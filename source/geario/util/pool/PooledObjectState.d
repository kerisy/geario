module geario.util.pool.PooledObjectState;



/**
 * Provides the possible states that a {@link PooledObject} may be in.
 *
 */
enum PooledObjectState {
    /**
     * In the queue, not in use.
     */
    IDLE,

    /**
     * In use.
     */
    ALLOCATED,

    // /**
    //  * In the queue, currently being tested for possible eviction.
    //  */
    // EVICTION,

    // /**
    //  * Not in the queue, currently being tested for possible eviction. An
    //  * attempt to borrow the object was made while being tested which removed it
    //  * from the queue. It should be returned to the head of the queue once
    //  * eviction testing completes.
    //  * TODO: Consider allocating object and ignoring the result of the eviction
    //  *       test.
    //  */
    // EVICTION_RETURN_TO_HEAD,

    // /**
    //  * In the queue, currently being validated.
    //  */
    // VALIDATION,

    // /**
    //  * Not in queue, currently being validated. The object was borrowed while
    //  * being validated and since testOnBorrow was configured, it was removed
    //  * from the queue and pre-allocated. It should be allocated once validation
    //  * completes.
    //  */
    // VALIDATION_PREALLOCATED,

    // /**
    //  * Not in queue, currently being validated. An attempt to borrow the object
    //  * was made while previously being tested for eviction which removed it from
    //  * the queue. It should be returned to the head of the queue once validation
    //  * completes.
    //  */
    // VALIDATION_RETURN_TO_HEAD,

    /**
     * Failed maintenance (e.g. eviction test or validation) and will be / has
     * been destroyed
     */
    INVALID,

    /**
     * Deemed abandoned, to be invalidated.
     */
    ABANDONED,

    /**
     * Returning to the pool.
     */
    RETURNING
}