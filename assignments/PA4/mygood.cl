-- class Main inherits IO{
--  x: Int;
--  y: String;
--  f: Foo;
--  main(): Object {{ 
--                    x <- 3; x <- 5; y <- "test"; f <- new Foo;
--                 }};
--  foo(): String {"test"};
-- };
-- class Foo {
--  x:Int <- 3;
-- };

-- class C {
-- 	a : Int;
-- 	b : Bool;
-- 	init(x : Int, y : Bool) : C {
--            {
-- 		a <- x;
-- 		b <- y;
-- 		self;
--            }
-- 	};
-- };

-- Class Main {
-- 	main():C {
-- 	  (new C).init(1,true)
-- 	};
-- };
