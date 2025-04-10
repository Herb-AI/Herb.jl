using PlutoStaticHTML

"""
Builds the Pluto notebooks in the specified directory. 
As part of the build, all notebooks are executed to make sure there is no 
deprecated code. 
"""
function build(tutorials_dir)
	@info "Building notebooks in $tutorials_dir"
	use_distributed = false
	output_format = documenter_output
	bopts = BuildOptions(tutorials_dir; use_distributed, output_format)
	build_notebooks(bopts)
end
