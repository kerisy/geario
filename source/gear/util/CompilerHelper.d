module gear.util.CompilerHelper;


/**
 * 
 */
class CompilerHelper {

    static bool IsGreaterThan(int ver) pure @safe @nogc nothrow {
        return __VERSION__ >= ver;
    }

    static bool IsLessThan(int ver) pure @safe @nogc nothrow {
        return __VERSION__ <= ver;
    }
}
