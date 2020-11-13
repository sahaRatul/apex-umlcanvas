({
    getDummyData: function () {
        return [{
            objectName: 'Account',
            objectApiName: 'Account',
            triggerDetails: {
                activeTriggers: ['test1', 'test2', 'test3'],
                inactiveTriggers: ['test4', 'test24', 'test233'],
                invalidTriggers: ['test231', 'test223', 'test323'],
                deletedTriggers: ['test123', 'test2232', 'test3323'],
                managedTriggers: ['test123', 'test2233', 'test32323']
            },
            duplicatedEvents: [{
                eventName: 'Before Insert',
                triggerName: ['xyz', 'sdfsf']
            }, {
                eventName: 'Before Update',
                triggerName: ['abc', 'uvw']
            }, {
                eventName: 'Before Delete',
                triggerName: ['cde, fgh']
            }, {
                eventName: 'After Insert',
                triggerName: ['test1', 'test2343']
            }],
            hardcodedIds: [{
                id: '1213232323',
                triggerName: 'abcxyz',
                lineNumber: 2
            },
            {
                id: '1213232323',
                triggerName: 'abcxyz',
                lineNumber: 2
            },
            {
                id: '1213232323',
                triggerName: 'abcxyz',
                lineNumber: 2
            }],
            loopDMLs: [{
                statement: 'select xyz from account',
                triggerName: 'dsfsdfsf',
                lineNumber: 12,
            }, {
                statement: 'select xyz from account',
                triggerName: 'dsfsdfsf',
                lineNumber: 12,
            }],
            queriesWithoutClause: [{
                statement: 'select xyz from account',
                triggerName: 'dsfsdfsf',
                lineNumber: 12,
            }, {
                statement: 'select xyz from account',
                triggerName: 'dsfsdfsf',
                lineNumber: 12,
            }, {
                statement: 'select xyz from account',
                triggerName: 'dsfsdfsf',
                lineNumber: 12,
            }]
        },
        {
            objectName: 'Opportunity',
            objectApiName: 'Opportunity',
            triggerDetails: {
                activeTriggers: ['test1', 'test3'],
                inactiveTriggers: ['test233'],
                invalidTriggers: ['test323'],
                deletedTriggers: ['test3323'],
                managedTriggers: ['test123', 'test2233', 'test32323']
            },
            duplicatedEvents: [{
                eventName: 'Before Insert',
                triggerName: ['xyz', 'sdfsf']
            }, {
                eventName: 'Before Delete',
                triggerName: ['cde, fgh']
            }, {
                eventName: 'After Insert',
                triggerName: ['test1', 'test2343']
            }],
            hardcodedIds: [{
                id: '1213232323',
                triggerName: 'abcxyz',
                lineNumber: 2
            }]
        },
        {
            objectName: 'Lead',
            objectApiName: 'Lead',
            triggerDetails: {
                activeTriggers: ['Lead1', 'Lead2', 'Lead3'],
                inactiveTriggers: ['test4', 'test24'],
                invalidTriggers: ['test231'],
                deletedTriggers: ['test123'],
                managedTriggers: ['test123', 'test2233', 'test32323']
            }
        },
        {
            objectName: 'User',
            objectApiName: 'User',
            triggerDetails: {
                activeTriggers: ['test1', 'test3'],
                inactiveTriggers: ['test4', 'test24', 'test233'],
                invalidTriggers: ['test231', 'test323'],
                deletedTriggers: ['test123', 'test2232', 'test3323'],
                managedTriggers: ['test123', 'test32323']
            }
        },
        {
            objectName: 'Case',
            objectApiName: 'Case',
            triggerDetails: {
                activeTriggers: ['test1', 'test2', 'test3'],
                inactiveTriggers: ['test4', 'test24', 'test233'],
                invalidTriggers: ['test231', 'test223', 'test323'],
                deletedTriggers: ['test123', 'test2232', 'test3323'],
                managedTriggers: ['test123', 'test2233', 'test32323']
            }
        }];
    }
})
