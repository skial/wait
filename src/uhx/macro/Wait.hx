package uhx.macro;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import uhx.macro.KlasImp;

using Lambda;
using uhu.macro.Jumla;
using haxe.macro.ExprTools;

/**
 * ...
 * @author Skial Bainn
 */
class Wait {
	
	private static function initialize() {
		try {
			if (!KlasImp.setup) {
				KlasImp.initalize();
			}
			
			KlasImp.INLINE_META.set( ~/@:wait\s/, Wait.handler );
		} catch (e:Dynamic) {
			// This assumes that `implements Klas` is not being used
			// but `@:autoBuild` or `@:build` metadata is being used 
			// with the provided `uhx.macro.Wait.build()` method.
		}
	}
	
	public static function handler(cls:ClassType, field:Field):Field {
		if (!Context.defined( 'display' )) switch(field.kind) {
			case FFun(method) if (method.expr != null): loop( method.expr );
			case _:
		}
		
		return field;
	}
	
	public static var STEP:Int = 0;
	
	public static function loop(e:Expr) {
		switch (e.expr) {
			case EBlock(exprs):
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
							var type = try Context.typeof( expr ) catch (e:Dynamic) expr.toString().find();
							
							args = args.mapi( function(index, expr) { 
								return transformArg(expr, type == null ? null : type.args()[index], fargs);
							} ).array();
							
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
							es.iter( loop );
							
					}
					
					nexprs.unshift( es );
					if (block != null) nexprs.unshift( block );
					
					index--;
					
				}
				
				if (nexprs.length > 0) {
					e.expr = EBlock( nexprs );
				}
				
			case _:
				e.iter( loop );
				
		}
	}
	
	public static function transformArg(arg:Expr, targ:{ name : String, opt : Bool, t : Type }, ?fargs:Array<FunctionArg>) {
		
		switch (arg) {
			case macro [$a { values } ]:
				
				var blanks = [for (f in fargs) macro null];
				for (value in values) {
					var type = targ == null ? macro:Dynamic : targ.t.toCType();
					var fi = fargs.push( { name: value.toString(), opt: true, type: type, value: macro null } ) - 1;
					blanks.push( macro _ );
				}
				
				var e1 = macro $i { 'block$STEP' };
				// Adding cast allows it to compile. This is just wrong, but I couldnt figure out the problem... crap burgers!
				var e2 = blanks.length > 0 ? macro cast $e1.bind($a { blanks } ) : macro $e1;
				arg.expr = e2.expr;
			
			case macro $call($a { args } ):
				//args = args.map( transformArg.bind(_, targ, fargs) );
				args = args.mapi( function(index, expr) return transformArg(expr, targ == null ? null : targ.t.args()[index], fargs) ).array();
				
			case _:
				
		}
		
		return arg;
	}
	
}