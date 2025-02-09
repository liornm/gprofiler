# gProfiler
gProfiler combines multiple sampling profilers to produce unified visualization of
what your CPU is spending time on, displaying stack traces of your processes
across native programs<sup id="a1">[1](#perf-native)</sup> (includes Golang), Java and Python runtimes, and kernel routines.

gProfiler can upload its results to the [Granulate Performance Studio](https://profiler.granulate.io/), which aggregates the results from different instances over different periods of time and can give you a holistic view of what is happening on your entire cluster.
To upload results, you will have to register and generate a token on the website.

gProfiler runs on Linux.

![Granulate Performance Studio example view](https://user-images.githubusercontent.com/58514213/124375504-36b0b200-dcab-11eb-8d64-caf20687a29f.gif)

# Running

This section describes the possible options to control gProfiler's output, and the various execution modes (as a container, as an executable, etc...)

## Output options

gProfiler can produce output in two ways:

* Create an aggregated, collapsed stack samples file (`profile_<timestamp>.col`)
  and a flamegraph file (`profile_<timestamp>.html`). Two symbolic links (`last_profile.col` and `last_flamegraph.html`) always point to the last output files.

  Use the `--output-dir`/`-o` option to specify the output directory.

  If `--rotating-output` is given, only the last results are kept (available via `last_profle.col` and `last_flamegraph.html`). This can be used to avoid increasing gProfiler's disk usage over time. Useful in conjunction with `--upload-results` (explained ahead) - historical results are available in the Granulate Performance Studio, and the very latest results are available locally.

  `--no-flamegraph` can be given to avoid generation of the `profile_<timestamp>.html` file - only the collapsed stack samples file will be created.

* Send the results to the Granulate Performance Studio for viewing online with
  filtering, insights, and more.

  Use the `--upload-results`/`-u` flag. Pass the `--token` option to specify the token
  provided by Granulate Performance Studio, and the `--service-name` option to specify an identifier
  for the collected profiles, as will be viewed in the [Granulate Performance Studio](https://profiler.granulate.io/). *Profiles sent from numerous
  gProfilers using the same service name will be aggregated together.*

Note: both flags can be used simultaneously, in which case gProfiler will create the local files *and* upload
the results.

## Profiling options
* `--profiling-frequency`: The sampling frequency of the profiling, in *hertz*.
* `--profiling-duration`: The duration of the each profiling session, in *seconds*.

The default profiling frequency is *11 hertz*. Using higher frequency will lead to more accurate results, but will create greater overhead on the profiled system & programs.

For each profiling session (each profiling duration), gProfiler produces outputs (writing local files and/or uploading the results to the Granulate Performance Studio).

### Java profiling options

* `--no-java` or `--java-mode disabled`: Disable profilers for Java.

### Python profiling options
* `--no-python`: Alias of `--python-mode disabled`.
* `--python-mode`: Controls which profiler is used for Python.
    * `auto` - (default) try with PyPerf (eBPF), fall back to py-spy.
    * `pyperf` - Use PyPerf with no py-spy fallback.
    * `pyspy` - Use py-spy.
    * `disabled` - Disable profilers for Python.

Profiling using eBPF incurs lower overhead & provides kernel stacks. This (currently) requires kernel headers to be installed.

### PHP profiling options
* `--no-php` or `--php-mode disabled`: Disable profilers for PHP.
* `--php-proc-filter`: Process filter (`pgrep`) to select PHP processes for profiling (this is phpspy's `-P` option)

### Ruby profiling options
* `--no-ruby` or `--ruby-mode disabled`: Disable profilers for Ruby.

### NodeJS profiling options
* `--nodejs-mode`: Controls which profiler is used for NodeJS.
     * `none` - (default) no profiler is used.
     * `perf` - augment the system profiler (`perf`) results with jitdump files generated by NodeJS. This requires running your `node` processes with `--perf-prof` (and for Node >= 10, with `--interpreted-frames-native-stack`). See this [NodeJS page](https://nodejs.org/en/docs/guides/diagnostics-flamegraph/) for more information.

### System profiling options

* `--perf-mode`: Controls the global perf strategy. Must be one of the following options:
    * `fp` - Use Frame Pointers for the call graph
    * `dwarf` - Use DWARF for the call graph (adds the `--call-graph dwarf` argument to the `perf` command)
    * `smart` - Run both `fp` and `dwarf`, then choose the result with the highest average of stack frames count, per process.
    * `disabled` - Avoids running `perf` at all. See [perf-less mode](#perf-less-mode).

## Other options
### Sending logs to server
**By default, gProfiler sends logs to Granulate Performance Studio** (when using `--upload-results`/`-u` flag)
This behavior can be disabled by passing `--dont-send-logs` or the setting environment variable `GPROFILER_DONT_SEND_LOGS=1`.

### Continuous mode
gProfiler can be run in a continuous mode, profiling periodically, using the `--continuous`/`-c` flag.
Note that when using `--continuous` with `--output-dir`, a new file will be created during *each* sampling interval.
Aggregations are only available when uploading to the Granulate Performance Studio.

## Running as a Docker container
Run the following to have gProfiler running continuously, uploading to Granulate Performance Studio:
```bash
docker pull granulate/gprofiler:latest
docker run --name gprofiler -d --restart=always \
    --pid=host --userns=host --privileged \
    -v /lib/modules:/lib/modules:ro -v /usr/src:/usr/src:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
	granulate/gprofiler:latest -cu --token <token> --service-name <service> [options]
```

For profiling with eBPF, kernel headers must be accessible from within the container at
`/lib/modules/$(uname -r)/build`. On Ubuntu, this directory is a symlink pointing to `/usr/src`.
The command above mounts both of these directories.

## Running as an executable
Run the following to have gprofiler running continuously, uploading to Granulate Performance Studio:
```bash
wget https://github.com/Granulate/gprofiler/releases/latest/download/gprofiler
sudo chmod +x gprofiler
sudo ./gprofiler -cu --token <token> --service-name <service> [options]
```

gProfiler unpacks executables to `/tmp` by default; if your `/tmp` is marked with `noexec`,
you can add `TMPDIR=/proc/self/cwd` to have everything unpacked in your current working directory.
```bash
sudo TMPDIR=/proc/self/cwd ./gprofiler -cu --token <token> --service-name <service> [options]
```

#### Executable known issues
The following platforms are currently not supported with the gProfiler executable:
+ Alpine

**Remark:** container-based execution works and can be used in those cases.

## Running as a Kubernetes DaemonSet
See [gprofiler.yaml](deploy/k8s/gprofiler.yaml) for a basic template of a DaemonSet running gProfiler.
Make sure to insert the `GPROFILER_TOKEN` and `GPROFILER_SERVICE` variables in the appropriate location!

## Running from source
gProfiler requires Python 3.6+ to run.

```bash
pip3 install -r requirements.txt
./scripts/copy_resources_from_image.sh
```

Then, run the following **as root**:
```bash
python3 -m gprofiler [options]
```

# Theory of operation
gProfiler invokes `perf` in system wide mode, collecting profiling data for all running processes.
Alongside `perf`, gProfiler invokes runtime-specific profilers for processes based on these environments:
* Java runtimes (version 7+) based on the HotSpot JVM, including the Oracle JDK and other builds of OpenJDK like AdoptOpenJDK and Azul Zulu.
  * Uses async-profiler.
* The CPython interpreter, versions 2.7 and 3.5-3.9.
  * eBPF profiling (based on PyPerf) requires Linux 4.14 or higher; see [Python profiling options](#python-profiling-options) for more info.
  * If eBPF is not available for whatever reason, py-spy is used.
* PHP (Zend Engine), versions 7.0-8.0.
  * Uses [Granulate's fork](https://github.com/Granulate/phpspy/) of the phpspy project.
* Ruby versions (versions 1.9.1 to 3.0.1)
  * Uses [Granulate's fork](https://github.com/Granulate/rbspy) of the [rbspy](https://github.com/rbspy/rbspy) profiler.
* NodeJS (version >= 10 for functioning `--perf-prof`):
  * Uses `perf inject --jit` and NodeJS's ability to generate jitdump files. See [NodeJS profiling options](#nodejs-profiling-options).

The runtime-specific profilers produce stack traces that include runtime information (i.e, stacks of Java/Python functions), unlike `perf` which produces native stacks of the JVM / CPython interpreter.
The runtime stacks are then merged into the data collected by `perf`, substituting the *native* stacks `perf` has collected for those processes.

## perf-less mode

It is possible to run gProfiler without using `perf` - this is useful where `perf` can't be used, for whatever reason (e.g permissions). This mode is enabled by `--perf-mode disabled`.

In this mode, gProfiler uses runtime-specific profilers only, and their results are concatenated (instead of scaled into the results collected by `perf`). This means that, although the results from different profilers are viewed on the same graph, they are not necessarily of the same scale: so you can compare the samples count of Java to Java, but not Java to Python.

# Contribute
We welcome all feedback and suggestion through Github Issues:
* [Submit bugs and feature requests](https://github.com/granulate/gprofiler/issues)
* Upvote [popular feature requests](https://github.com/granulate/gprofiler/issues?q=is%3Aopen+is%3Aissue+label%3Aenhancement+sort%3Areactions-%2B1-desc+)

## Releasing a new version
1. Update `__version__` in `__init__.py`.
2. Create a tag with the same version (after merging the `__version__` update) and push it.

We recommend going through our [contribution guide](https://github.com/granulate/gprofiler/blob/master/CONTRIBUTING.md) for more details.

# Credits
* [async-profiler](https://github.com/jvm-profiling-tools/async-profiler) by [Andrei Pangin](https://github.com/apangin). See [our fork](https://github.com/Granulate/async-profiler).
* [py-spy](https://github.com/benfred/py-spy) by [Ben Frederickson](https://github.com/benfred). See [our fork](https://github.com/Granulate/py-spy).
* [bcc](https://github.com/iovisor/bcc) (for PyPerf) by the IO Visor project. See [our fork](https://github.com/Granulate/bcc).
* [phpspy](https://github.com/adsr/phpspy) by [Adam Saponara](https://github.com/adsr). See [our fork](https://github.com/Granulate/phpspy).
* [rbspy](https://github.com/rbspy/rbspy) by the rbspy project. See [our fork](https://github.com/Granulate/rbspy)

# Footnotes

<a name="perf-native">1</a>: To profile native programs that were compiled without frame pointers, make sure you use the `--perf-mode smart` (which is the default). Read more about it in the [Profiling options](#profiling-options) section[↩](#a1)
