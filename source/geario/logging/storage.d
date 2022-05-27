
module geario.logging.storage;

@system:
package:

import geario.logging.logger;
import geario.logging.config;

struct FileStorage
{
    import std.stdio;
    import std.file;

    /* Currently Logging file */
    File activeFile;
    /* Do file rolling */
    Rollover rollover;

    /**
     * Primary constructor
     *
     * Save config path and name
     */
    this(LoggerConfig config)
    {
        rollover = createRollover(config);

        createPath(rollover.activeFilePath());
        activeFile = File(rollover.activeFilePath(), "a");
    }

    /**
     * Extract logger type
     *
     * Throws: BundleException, LogCreateException
     */
    Rollover createRollover(LoggerConfig config)
    {
        RolloverFactory f = cast(RolloverFactory)Object.factory("geario.logging.storage." ~ config.rollingType ~ "Factory");

        if (f is null)
        {
            throw new  LoggerCreateException("Error create log rolling: " ~ config.rollingType  ~ "  is Illegal rolling type.");
        }
        Rollover r = f.factory(config);
        return r;
    }

    /**
     * Extract logger type
     *
     * Throws: $(D ErrnoException)
     */
    void saveMsg(string msg)
    {
        if (!activeFile.name.exists)
        {
            activeFile = File(rollover.activeFilePath(), "w");
        }
        else if (rollover.roll(msg))
        {
            activeFile.detach();
            rollover.carry();
            activeFile = File(rollover.activeFilePath(), "w");
        }
        else if (!activeFile.isOpen())
        {
            activeFile.open("a");
        }
        activeFile.writeln(msg);
    }

    /**
     * Flush log file
     */
    void flush()
    {
        activeFile.flush;
    }
}


/**
 * Create file
 */
void createPath(string fileFullName)
{
    import std.path:dirName;
    import std.file:mkdirRecurse;
    import std.file:exists;

    string dir = dirName(fileFullName);

    if ((dir.length != 0) && (!exists(dir)))
    {
        mkdirRecurse(dir);
    }
}



/**
 * Rollover Creating interface
 *
 * Use by FileStorage for create new Rollover
 *
 * ====================================================================================
 */
interface RolloverFactory
{
    Rollover factory(LoggerConfig config);
}


/**
 * Base rollover class
 */
class Rollover
{
    import std.path;
    import std.string;
    import std.typecons;

    /* Control of size and number of log files */
    LoggerConfig config;
    /* Path and file name template */
    mixin(addVal!(immutable string, "path", "protected"));
    /* Work diroctory */
    mixin(addVal!(immutable string, "dir", "protected"));
    /* Log file base name template */
    mixin(addVal!(immutable string, "baseName", "protected"));
    /* Log file extension */
    mixin(addVal!(immutable string, "ext", "protected"));
    /* Path to main log file */
    mixin(addVar!(string, "activeFilePath", "protected", "protected"));

    /**
     * Primary constructor
     */
    this(LoggerConfig config)
    {
        _path = config.filename;
        auto fileInfo = parseConfigFilePath(path);
        _dir = fileInfo[0];
        _baseName = fileInfo[1];
        _ext = fileInfo[2];
        init();
    }

    /**
     * Rollover start init
     */
    void init()
    {
        activeFilePath = path;
    }

    /**
     * Parse configuration file path and base name and save to members
     */
    auto parseConfigFilePath(string rawConfigFile)
    {
        string configFile = buildNormalizedPath(rawConfigFile);

        immutable dir = configFile.dirName;
        string fullBaseName = std.path.baseName(configFile);
        auto ldotPos = fullBaseName.lastIndexOf(".");
        immutable ext = (ldotPos > 0)?fullBaseName[ldotPos+1..$]:"log";
        immutable baseName = (ldotPos > 0)?fullBaseName[0..ldotPos]:fullBaseName;

        return tuple(dir, baseName, ext);
    }

    /**
     * Do files rolling by default
     */
    bool roll(string msg)
    {
        return false;
    }

    void carry(){}
}


/**
 * Factory for SizeBasedRollover
 *
 * ====================================================================================
 */
class SizeBasedRolloverFactory:RolloverFactory
{
    override Rollover factory(LoggerConfig config)
    {
        return new SizeBasedRollover(config);
    }
}


/**
 * Control of size and number of log files
 */
class SizeBasedRollover:Rollover
{
    import std.file;
    import std.regex;
    import std.algorithm;
    import std.array;


    /* Max size of one file */
    uint maxSize;
    /* Max number of working files */
    uint maxHistory;

    /* Primary constructor */
    this(LoggerConfig config)
    {
        super(config);

        maxSize = config.maxSize;
        maxHistory = config.maxHistory;
    }

    /**
     * Extract number fron configuration data
     *
     * Throws: LogException
     */
    uint extractSize(string size)
    {
        import std.uni : toLower;
        import std.uni : toUpper;
        import std.conv;

        uint nsize = 0;
        auto n = matchAll(size, regex(`\d*`));
        if (!n.empty && (n.hit.length != 0))
        {
            nsize = to!int(n.hit);
            auto m = matchAll(size, regex(`\D{1}`));
            if (!m.empty && (m.hit.length != 0))
            {
                switch(m.hit.toUpper)
                {
                    case "K":
                        nsize *= KB;
                        break;
                    case "M":
                        nsize *= MB;
                        break;
                    case "G":
                        nsize *= GB;
                        break;
                    case "T":
                        nsize *= TB;
                        break;
                    case "P":
                        nsize *= PB;
                        break;
                    default:
                        throw new LoggerException("In Logger configuration uncorrect number: " ~ size);
                }
            }
        }
        return nsize;
    }


    enum KB = 1024;
    enum MB = KB*1024;
    enum GB = MB*1024;
    enum TB = GB*1024;
    enum PB = TB*1024;

    /**
     * Scan work directory
     * save needed files to pool
    	 */
    string[] scanDir()
    {
        import std.algorithm.sorting:sort;
        bool tc(string s)
        {
            static import std.path;
            auto base = std.path.baseName(s);
            auto m = matchAll(base, regex(baseName ~ `\d*\.` ~ ext));
            if (m.empty || (m.hit != base))
            {
                return false;
            }
            return true;
        }

        return std.file.dirEntries(dir, SpanMode.shallow)
            .filter!(a => a.isFile)
            .map!(a => a.name)
            .filter!(a => tc(a))
            .array
            .sort!("a < b")
            .array;
    }

    /**
     * Do files rolling by size
     */
    override
    bool roll(string msg)
    {
        auto filePool = scanDir();
        if (filePool.length == 0)
        {
            return false;
        }
        if ((getSize(filePool[0]) + msg.length) >= maxSize)
        {
            //if ((filePool.front.getSize == 0) throw
            if (filePool.length >= maxHistory)
            {
                std.file.remove(filePool[$-1]);
                filePool = filePool[0..$-1];
            }
            //carry(filePool);
            return true;
        }
        return false;
    }

    /**
     * Rename log files
     */
    override
    void carry()
    {
        import std.conv;
        import std.path;

        auto filePool = scanDir();
        foreach_reverse(ref file; filePool)
        {
            auto newFile = dir ~ dirSeparator ~ baseName ~ to!string(extractNum(file)+1) ~ "." ~ ext;
            std.file.rename(file, newFile);
            file = newFile;
        }
    }

    /**
     * Extract number from file name
     */
    uint extractNum(string file)
    {
        import std.conv;

        uint num = 0;
        try
        {
            static import std.path;
            import std.string;
            auto fch = std.path.baseName(file).chompPrefix(baseName);
            auto m = matchAll(fch, regex(`\d*`));

            if (!m.empty && m.hit.length > 0)
            {
                num = to!uint(m.hit);
            }
        }
        catch (Exception e)
        {
            throw new Exception("Uncorrect log file name: " ~ file ~ "  -> " ~ e.msg);
        }
        return num;
    }

}
