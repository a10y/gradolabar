package = "gradolabar"
version = "scm-1"

source = {
   url = "git://github.com/alexbw/gradolabar.git",
}

description = {
   summary = "Source-to-source automatic differentiation for Torch.",
   homepage = "",
   license = "MIT",
}

dependencies = {
   "torch >= 7.0",
   "lua-parser >= 0.1.1-1"
}

build = {
   type = "command",
   build_command = 'cmake -E make_directory build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(LUA_BINDIR)/.." -DCMAKE_INSTALL_PREFIX="$(PREFIX)" && $(MAKE)',
   install_command = "cd build && $(MAKE) install"
}
