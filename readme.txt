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


Wild West Taxi Driver: Your Guide to the Passenger Transport Life 🚂
Howdy, partner! Welcome to the Passenger Transport Script for RedM, where you trade your spurs for a steering wheel (or reins?) and become the slickest taxi driver in the Wild West. Get ready to haul folks across the prairie, puff on a cigar like a true legend, and maybe dodge a rattlesnake or two. This README is your trusty map to becoming the Uber of 1890s!
What’s This Crazy Ride About? 🤠
This here script lets you play taxi driver in a world full of saloons, shootouts, and sassy NPCs. You’ll spawn a fancy wagon, pick up passengers who are plumb tired of walkin’, and drop ‘em off at their favorite spots—whether it’s a saloon or some dusty outpost. Along the way, you’ll look cooler than a barrel of moonshine with a cigar-smoking animation that screams “I’m the boss of this trail.”
What You’ll Be Doin’:

Drivin’ a shiny wagon (it’s called coach3_cutscene, but you can call it Betsy).
Pickin’ up NPCs who think your ride’s the cat’s pajamas.
Droppin’ folks off at marked spots, either automatically or with a fancy menu.
Lightin’ up a cigar after every drop-off to show the town who’s the slickest driver around.
Followin’ GPS routes (or just squintin’ at waypoints) to get where you’re goin’.
Earnin’ rewards for every passenger who doesn’t complain about your drivin’.

How to Get Rollin’ 🎉

Get Hired as a Taxi Driver: Head to wherever your server hands out jobs and snag the “taxi” job. If you ain’t got it, you’re just a cowboy with no cab!
Find a Spawn Point: Look for a blip on your map (usually a fancy icon) or wander to a marked spot in town. It’s like a stable, but for wagons.
Spawn Your Wagon: Stand at the spawn point, press the prompt (probably the Space key), and watch your shiny taxi wagon appear. Yee-haw!
Pick Up Passengers: Stop your wagon (don’t be speedin’ like you’re in a stagecoach robbery) and wait for NPCs to hop in. They’ll only board if you’re slower than a lazy mule.
Drop ‘Em Off: Drive to the marked drop-off spot (check your map or GPS). Stop the wagon, and passengers will hop out automatically—or you can use the drop-off menu for extra flair.
Strike a Pose: After droppin’ folks off, you’ll jump out and light a cigar for 7 seconds of pure cowboy swagger. Don’t worry, the cigar vanishes before you burn your hat.
Keep It Goin’: Head back to your wagon to pick up more passengers. Don’t leave it unattended too long, or it might end up in a poker game!

Pro Tips for Ridin’ in Style 🌟

Stay Still to Pick Up: Your wagon’s gotta be near stopped (slower than 1 m/s) for passengers to climb aboard. No driftin’ like you’re in a Wild West Fast & Furious.
Check Your Job: If you switch jobs or get fired, your taxi gig ends faster than a duel at high noon. Stay a taxi driver to keep the mission goin’.
Follow the Blips: Map blips show spawn points and drop-offs. If your server’s got GPS enabled, you’ll get fancy red lines to guide you. If not, use waypoints and pretend you’re a pioneer.
Don’t Crash: If your wagon gets smashed or you take a dirt nap (a.k.a. die), the mission’s over. Protect Betsy like she’s your best horse.
Clear the Wagon: Got a wagon causin’ a ruckus? Type /deletetaxi in the chat to make it disappear faster than a bandit in a dust storm.
Cigar Time is Cool Time: That smokin’ animation after drop-offs is mandatory. Lean into it—you’re not just a driver, you’re a legend.

Things That Might Trip You Up (a.k.a. “The Tumbleweeds of Taxi Life”) 😅

Passengers Are Picky: Some NPCs take their sweet time gettin’ in. If they don’t board in 20 seconds, they’re outta luck (and gone from the game).
Wagon Limits: You can only carry so many passengers (check your server’s settings). Don’t try to stuff the whole town in there!
Smokin’ Swagger: The cigar animation makes you look awesome, but don’t be surprised if NPCs start askin’ for your autograph.
No Wagon, No Game: If you hop out and wander too far, or if your wagon gets turned into kindling, the mission ends. Keep an eye on your ride.
Job Drama: Lose your taxi job mid-mission, and it’s back to herdin’ cattle for you. Stay employed!

Got Questions or Trouble? 🐴

My wagon won’t spawn! Make sure you’re a taxi driver and at a spawn point. If it’s still actin’ up, holler at your server admin—they might’ve forgotten to feed the script its oats.
Passengers won’t board! Check that your wagon’s stopped and you’re far enough from drop-off points. NPCs won’t hop in if you’re too close to their destination.
I look too cool smokin’ that cigar! Sorry, partner, that’s just the price of bein’ a Wild West taxi legend.
Where’s my reward? Droppin’ off passengers should earn you some cash or goodies. If not, your server might be stingier than a saloon owner at last call.

Final Word from the Trail 🌄
Saddle up, grab your reins, and get ready to be the best darn taxi driver in RedM! Whether you’re haulin’ folks to the saloon or showin’ off your cigar-smokin’ skills, this script is your ticket to Wild West fame. Now go out there and make those passengers say, “That’s one rootin’-tootin’ ride!”
Happy drivin’, and watch out for them tumbleweeds! 🚂
