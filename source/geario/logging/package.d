
module geario.logging;

public import geario.logging.logger;

@safe:

/**
 * Create loggers from config bundle
 *
 * Throws: BundleException, LogCreateException
 */
void createLogger(immutable string loggerName)
{
    create(loggerName);
}

/**
 * Get created logger interface to work with it
 *
 * Throws: LogException
 */
Logger getLogger(immutable string loggerName)
{
    return get(loggerName);
}

/**
 * Delete logger
 *
 * Throws: Exception
 */
void deleteLogger(immutable string loggerName)
{
    remove(loggerName);
}

/**
 * Check is Logger present
 */
bool isLogger(immutable string loggerName) nothrow
{
    return isCreated(loggerName);
}

/**
 * Set path to file for save loggers exception information
 *
 * Throws: Exception
 */
void setErrFile(immutable string file)
{
    setErrorFile(file);
}


// unittest
// {
//     createLogger("DebugLogger");
//     setErrorFile("./log/error.log");

//     auto log2 = getLogger("DebugLogger");
//     log2.trace("trace msg");
//     log2.info("info msg %d", 2);
//     log2.error("error test %d %s", 3, "msg");
// }
