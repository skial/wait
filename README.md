Wait
====

An Await implementation inspired by CSharp's await keyword 
discovered in the [async support in nodejs](https://github.com/koush/node/wiki/"async"-support-in-node.js)
article.

[![Build Status](https://next.travis-ci.org/skial/wait.svg?branch=master)](https://next.travis-ci.org/skial/wait)

## Install

`haxelib git wait https://github.com/skial/wait.git`

And add `-lib wait` to your `hxml` file.
	
## Usage

You have two options, use Wait with [Klas](https://github.com/skial/klas/) or not.

#### With Klas

```Haxe
package ;

class Main implements Klas {
	
	public function new() {
		@:wait asyncTask(100, 10000, [success], [error]);
		trace( success );
	}
	
	public function asyncTask(start:Int, finish:Int, success:String->Void, error:String->Void) {
		// Do something
	}
	
}
```

#### Without Klas

```Haxe
package ;

@:autoBuild( uhx.macro.Wait.build() )
class Main {
	
	public function new() {
		@:wait asyncTask(100, 10000, [success], [error]);
		trace( success );
	}
	
	public function asyncTask(start:Int, finish:Int, success:String->Void, error:String->Void) {
		// Do something
	}
	
}
```

## Explanation

Wait transforms any method thats contains `@:wait` by taking all code after the
encountered `@:wait`. It then inserts a local method whose body contains 
the captured code, before the encountered `@:wait`.

The following example is the transformed method body of the constructor from the
examples above.

+ Both `[success]` and `[error]` indicate to the build macro that these parameters
are methods, both taking a single parameter themselves.
+ The code `@:wait callback(1, 2, [c, d, e])` tells the build macro to create a
method that has three parameters named `c`, `d` and `e`.
+ The marker `[]` can appear at any point in a method call `@:wait callback(1, [a, b], 2, 3, [c], 4, [d, e])`
+ An empty marker, `[]` equals `Void->Void`.

```Haxe
public function new() {
    var block0 = function(?success:String->Void = null, ?error:String->Void = null) {
            trace(success);
    };
    asyncTask(100, 10000, cast block0.bind(_), cast block0.bind(null, _));
}
```

## Tests

You can find Waits tests in the [uhu-spec](https://github.com/skial/uhu-spec/blob/master/src/uhx/macro/WaitSpec.hx) library.