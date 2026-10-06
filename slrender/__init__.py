"""slrender — headless renderer for Unity ShaderLab shaders (see README.md)."""
from .render import Renderer, TextureSpec, to_image  # noqa: F401
from .compiler import CompileError, compile_pass  # noqa: F401
from . import shaderlab  # noqa: F401

__version__ = "0.1.0"
