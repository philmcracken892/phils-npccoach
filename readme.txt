add to radial wheel 

['taxi'] = {
        {
            id = 'toggletaxi',
            title = 'toggletaxi',
            icon = 'exclamation',
            type = 'command',
            event = 'taxi',
            shouldClose = true
        },
		{
            id = 'deletetaxi',
            title = 'deletetaxi',
            icon = 'exclamation',
            type = 'command',
            event = 'deletetaxi',
            shouldClose = true
        },
    },
	
	
	then addto rsg-core jobs lua
	
	taxi = {
        label = 'taxi',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = { name = 'taxi', isboss = true, payment = 10 },
            
        },
    },