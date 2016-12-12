# gradolabar
Experiments with source-to-source automatic differentiation

Jeff Siskind already did it (as usual), and I learned it at the "Future of Gradient-based Machine Learning" workshop at NIPS 2016.

The three elements of a source-to-source automatic differentiation system:

- `ast = code(function_pointer)` takes a function pointer, and grabs a string representation of the function (or AST).  
- `new_ast = transform(ast)` takes an AST, and extends it to compute the gradient of the original function using automatic differentiation.  
- `new_function_pointer = compile(new_ast)` takes in an AST (extended, or not), optionally applies optimization passes, and then returns a linked-and-ready function pointer to run.

This repository has done 1.5 / 3 pieces here so far. Given a function pointer (this is all in Lua, by the way), I can grab its source code, and parse it into an AST.  
Given an AST, you can use the code here to execute all kinds of rewrite rules. Autodiff can be viewed as a large cookbook of rewrite recipes that exclusively extend, as opposed to modify, an AST.  
There is absolutely no thought towards performance here, I was just playing around to see how hard it would be to get all the pieces together.  
