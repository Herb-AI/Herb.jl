using PlutoStaticHTML

function build(tutorials_dir)
    @info "Building notebooks in $tutorials_dir"
    use_distributed = false
    output_format = documenter_output
    bopts = BuildOptions(tutorials_dir; use_distributed, output_format)
    build_notebooks(bopts)
end