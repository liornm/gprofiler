
def get_run_mode() -> str:
    if os.getenv("GPROFILER_IN_K8S") is not None:  # set in k8s/gprofiler.yaml
        return "k8s"
    elif os.getenv("GPROFILER_IN_CONTAINER") is not None:  # set by our Dockerfile
        return "container"
    elif os.getenv("STATICX_BUNDLE_DIR") is not None:  # set by staticx
        return "standalone_executable"
    else:
        return "local_python"

