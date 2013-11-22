package uhx.macro;

import haxe.ds.Option;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import uhx.macro.klas.Handler;

using uhu.macro.Jumla;
using haxe.macro.ExprTools;

/**
 * ...
 * @author Skial Bainn
 */
class Wait {
	
	private static function initialize() {
		try {
			if (!Handler.setup) {
				Handler.initalize();
			}
			
			Handler.DEFAULTS.push(Wait.handler);
		} catch (e:Dynamic) {
			// This assumes that `implements Klas` is not being used
			// but `@:autoBuild` or `@:build` metadata is being used 
			// with the provided `uhx.macro.Wait.build()` method.
		}
	}
	
	public static function build():Array<Field> {
		return handler( Context.getLocalClass().get(), Context.getBuildFields() );
	}

	public static function handler(cls:ClassType, fields:Array<Field>):Array<Field> {
		
		if (!Context.defined( 'display' )) {
			for (field in fields) {
				
				switch (field.kind) {
					case FFun(method) if(method.expr != null): loop( method.expr );
					case _:
				}
				
			}
		}
		
		return fields;
	}
	
	public static var STEP:Int = 0;
	
	public static function loop(e:Expr) {
		switch (e.expr) {
			case EBlock(exprs):
				var vars = [];
				var nexprs = [];
				var len = exprs.length;
				var index = len-1;
				
				STEP = 0;
				
				while (index >= 0) {
					var es = exprs[index];
					var block = null;
					
					switch (es) {
						case macro @:wait $expr( $a { args } ):
							var fargs = [];
							var type = expr.toString().find();
							
							args = args.map( transformArg.bind(_, fargs) );
							
							block =  {expr: EVars([{ 
								name: 'block$STEP', 
								type: null, 
								expr: { 
									expr: EFunction( null, {
										args: fargs,
										ret: null,
										params: [],
										expr: { 
											expr: EBlock( nexprs.copy() ), 
											pos: es.pos 
										}
									} ), pos: es.pos 
								} 
							}]), pos: es.pos };
							
							nexprs = [];
							
							STEP++;
							
						case _:
							ExprTools.iter( es, loop );
							
					}
					
					nexprs.unshift( es );
					if (block != null) nexprs.unshift( block );
					
					index--;
					
				}
				
				if (nexprs.length > 0) {
					e.expr = EBlock( nexprs );
				}
				
			case _:
				ExprTools.iter( e, loop );
				
		}
	}
	
	public static function transformArg(arg:Expr, ?fargs:Array<FunctionArg>) {
		switch (arg) {
			case macro [$a { values } ]:
				
				var blanks = [for (f in fargs) macro null];
				for (value in values) {
					var fi = fargs.push( { name: value.toString(), opt: true, type: null, value: macro null } ) - 1;
					blanks.push( macro _ );
				}
				
				var e1 = macro $i { 'block$STEP' };
				var e2 = blanks.length > 0 ? macro $e1.bind($a { blanks } ) : macro $e1;
				arg.expr = e2.expr;
			
			case macro $call($a { args } ):
				args = args.map( transformArg.bind(_, fargs) );
				
			case _:
				
		}
		
		return arg;
	}
	
}