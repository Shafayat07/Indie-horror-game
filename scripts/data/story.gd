class_name Story
## All written content: objectives, documents, radio transmissions and the
## recordings the field recorder can capture. Kept in one place so tone and
## facts stay consistent.
##
## The story in one breath: the sea around Vey Isle remembers everyone it
## takes. Their voices come back. Something beneath the island learned to use
## them. The bell was a warning; the researchers disturbed what it warned of.
## Now the island is calling again — and it has already written down Elias.

const OBJECTIVES := {
	"leave_boat": "Step off the boat onto the dock.",
	"find_shed": "Check the maintenance shed at the end of the dock.",
	"take_recorder": "Take the field recorder from the workbench.",
	"try_listen": "Hold the recorder up and listen.  [Q]",
	"record_echo": "Open the recorder [R] and record the footsteps [Left Mouse].",
	"go_inland": "Follow the path inland to the settlement.",
	"find_key": "Find the key to the weather station.",
	"reach_station": "Take the west road to the weather station.",
	"restore_power": "Restore power to the weather station. The generator room door is outside, on the south wall.",
	"find_sequence": "Find the correct relay order. The tape deck in the station office holds it — listen to it [Q].",
	"activate_transmitter": "Transmit the report from the monitoring room.",
	"find_caves": "The tide is out. Find the exposed caves below the east cliffs.",
	"open_gate": "Open the iron seal in the caves.",
	"cross_caves": "Follow the caves north, beneath the lighthouse.",
	"release_seal": "Release the seal on the lighthouse's lower level.",
	"descend": "Descend to the transmitter.",
	"arm_transmitter": "Engage the transmitter's power couplings.",
	"choose": "Decide what the island says next.",
	"return_boat": "Return to the boat.",
	"leave": "Leave Vey Isle.",
}

## Chapter title cards shown the first time each place is reached: [flag, numeral, title, premise]
const CHAPTERS := [
	["ch_dock", "I", "THE FLOODED DOCK", "You are Elias Vale. You came to fix a weather station. The island was expecting you."],
	["ch_settlement", "II", "THE SETTLEMENT", "They lived with the voices for generations. Then, one night, they answered."],
	["ch_station", "III", "THE WEATHER STATION", "The researchers came here to listen to the sea."],
	["ch_forest", "IV", "BLACKWOOD", "People went into these woods to look for the missing. Tomas Kell never came out."],
	["ch_graveyard", "V", "THE SHIP GRAVEYARD", "Every ship that answered the island's call is still here."],
	["ch_lowvey", "VI", "LOW VEY", "Drowned in 1923. The sea called them by name. Tonight the tide gives it back."],
	["ch_caves", "VII", "THE TIDAL CAVES", "This is where the voices come from."],
	["ch_annex", "VIII", "THE ANNEX", "Project Morrow. They tried to make people hear the island."],
	["ch_lighthouse", "IX", "THE LIGHTHOUSE", "Aldo Wren kept it lit to warn ships away. They made it call them in."],
	["ch_chamber", "X", "WHAT THE TIDE REMEMBERS", "The sea never forgets the people it takes."],
]

## Elias's notebook [J]: what he has worked out, in plain words. [flag, title, text]
const JOURNAL := [
	["j_arrival", "Why I'm here", "I was sent to restore the dead weather station on Vey Isle and send its last report. It has been sending a distress call for six years with no power. On the boat, the radio played my own voice."],
	["j_preecho", "Footsteps", "Some sounds here come before the thing that makes them. My footsteps reached the dock before I did. The recorder hears these sounds better when I listen [Q]."],
	["j_replay", "The recorder", "If I record a sound and replay it, the island sends it back — loudly — to the place I recorded it. I can use that to lure things away. But the recorder's own speaker can be heard too."],
	["j_curse", "The old warning", "The villagers believed the sea remembers everyone it takes, and sometimes gives their voices back. Their rules: never answer a voice from the water after the bell rings. Paint a white ring on the door. Never follow anyone who calls your name from the dark — it isn't them."],
	["j_listener", "The Listener", "Something walks the island: tall, made of wet rope, net and old ship parts, with an iron cage for a head. It goes to sounds — even ones that haven't happened yet. It sees badly: crouch and kill the light. It never crosses a doorway, and never enters a room with a WHITE RING on the door. The village stories describe it long before the researchers came."],
	["j_key", "The station key", "The radio told me where the key was before I found it: in the blue house, inside a clock that runs backwards."],
	["j_station", "The researchers", "In 1968 Project Pelagic came to study the island's voices and the sounds that come too early. Dr. Ruth Marrow led it. Her first notes are curious. Her last ones are frightened."],
	["j_tide", "The tide", "When I sent the report, the sea pulled back from the island. The radio — in my voice — told me to stay out of the caves. The drowned village of Low Vey is lying out on the shore."],
	["j_lowvey", "Low Vey", "Low Vey drowned in 1923. The night before, every sound stopped for thirteen seconds, then a bell rang under the water. They didn't fear the sea because it was dangerous. They feared it because it called them by name."],
	["j_morrow", "Project Morrow", "Under the caves, Dr. Edwin Morrow operated on people who heard the voices, to make them hear more clearly. Twelve went in. Eleven walked into the sea. Kell was the twelfth. The thirteenth name on the list is mine."],
	["j_kell", "Tomas Kell", "Kell was the station's radio operator. He joined to help find missing sailors — his brother among them. Then he began hearing a voice like his own. Now he lives in Blackwood, changed, and hunts by clicking like a bat. He sleeps in a rock cave by the old radio tower and comes out when the bell strikes the hour [T: watch]. If his clicks pass over me I must not move. Light hurts him."],
	["j_pelagic", "The missing ships", "The MV Pelagic heard a voice calling from the island and sailed toward it. Half her crew said it was someone they knew. She never left. Every boat that came looking is wrecked beside her."],
	["j_last", "The last recording", "Kell left a message: three recordings together — Morrow's tape, the Pelagic's mayday and his own — would let the transmitter hear its own silence. I can play them in the chamber."],
	["j_truth", "What happened here", "People drowned. Their voices stayed in the sea. Something beneath the island learned to use them. The bell was a warning. The researchers tuned the lighthouse to the drowned bell, turned it up, and something answered. It has been calling ever since. Tonight it is calling me."],
	["j_suha", "Suha", "Suha called me tonight on radios that can't reach the mainland. It sounded just like her. I wanted it to be her."],
	["j_choice", "The choice", "I can BREAK the transmitter (the island goes quiet — for a while; no warning leaves), or SEND the report (the mainland learns what's out here, but the voices go out with it)."],
]

## Elias's thoughts (subtitled as ELIAS; not voiced). id -> line
const ELIAS := {
	"arrive": "That was my voice. I haven't said that yet.",
	"dock_steps": "Footsteps behind me... my footsteps. They kept going after I stopped.",
	"recorder": "A field recorder. Someone left it here for me.",
	"listen": "Under the hiss — my footsteps again. And my voice.",
	"settlement": "Lights in the windows. No power lines. No people.",
	"listener_first": "Something's standing on the lighthouse road. Too tall to be a man.",
	"teahouse": "The tea's still warm. The chair is turned to face the wall.",
	"key": "The station key. The clock is running backwards around it.",
	"bell": "The bell just rang. It isn't moving.",
	"station": "The weather station. Lights on, report sent, then I'm gone.",
	"tide_out": "The sea is pulling away from the island. That isn't possible.",
	"forest": "Something is clicking up in the trees.",
	"cabin": "Kell's hut. Tally marks on every wall — hours.",
	"roost": "He's up there. Hanging. Breathing like a man asleep.",
	"kell_wakes": "He's awake! The tower floodlight — light hurts him!",
	"kell_dead": "In the light he looked like a man again. I'm sorry, Tomas.",
	"graveyard": "The Pelagic. And every boat that came looking for her.",
	"cargo": "Oh God. They kept the crew in the hold.",
	"lowvey": "Low Vey. The drowned village. The tide brought it back.",
	"silence": "...",
	"caves": "The caves the radio warned me about. Of course I'm going in.",
	"annex": "A hospital. Under the sea.",
	"exam": "They cut into people's ears. To make them hear the island.",
	"lighthouse": "Two tapes, both in my voice, telling me opposite things.",
	"chamber": "This is it. This is what's been calling.",
	"lodger": "...Who's there?",
	"dock_name": "Someone just said my name. From under the dock.",
	"wardrobe": "Knocking. From inside. It's a child's knock.",
	"mirror": "There was someone behind me in the mirror. There's no one here.",
	"stairs": "Someone's climbing the stairs. I haven't moved.",
	"sea_bell": "A bell. Out there, under the water.",
	"thirteen": "Thirteen. It rang thirteen times.",
}

## Things to examine: id -> [prompt, Elias's comment]
const EXAMINE := {
	"boat_engine": ["Examine the engine", "The diesel is still warm. I'm the only one who's been on this boat tonight. I think."],
	"shed_photo": ["Look at the photograph", "The Pelagic team in front of the lighthouse, 1971. Every face is scratched out except one, at the back. He's wearing my coat."],
	"teahouse_cup": ["Look at the teacup", "Still steaming. Lipstick on the rim — and a year of dust on the saucer."],
	"teahouse_chair": ["Look at the chair", "Someone sat facing the wall so they wouldn't go to the window. There are nail marks in the plaster where they held on."],
	"blue_bed": ["Look at the bed", "Nell Halloran's bed. The blanket is soaked and smells of the sea."],
	"office_map": ["Study the wall map", "Red pins where people vanished. They make a path from the shore to the lighthouse."],
	"station_board": ["Read the chalkboard", "'HOURS SINCE THE 13 SECONDS: 4,117.' The count stopped years ago. The chalk is fresh."],
	"cabin_radio": ["Look at the radio rig", "Built from station parts and aimed at the lighthouse. Scratched on the dial: 'IT TALKS BACK'."],
	"cabin_mirror": ["Look in the mirror", "Painted over. Written in the paint from the inside: 'I DON'T LOOK LIKE ME'."],
	"forest_remains": ["Look closer", "Wrapped in fishing net and hung up like a catch. Whoever it was, they came here looking for someone."],
	"ship_radio": ["Examine the radio", "The Pelagic's radio. The valves are glowing. There's no battery."],
	"cargo_net": ["Look at the net", "A cargo net full of... crew. Their ears are gone. Cut away neatly."],
	"lowvey_table": ["Look at the table", "A family at supper, under fifty years of sea. Their heads are all turned the same way. Toward the lighthouse."],
	"annex_jars": ["Look at the jars", "Human ears in jars, labelled with names. One label is blank."],
	"annex_chair": ["Look at the chair", "A chair with straps, and a headset bolted into the bone of whoever sat here."],
	"annex_list": ["Read the subject list", "SUBJECTS 1–12, crossed out. SUBJECT 13: E. VALE — 'arrives by sea'. That's me."],
	"chamber_dial": ["Look at the dials", "Every needle points at the same time: 03:12."],
	"family_photo": ["Look at the photographs", "A family on the slipway, squinting into the sun. Someone has drawn a white ring around the father. Under it: 'came back 3 nights. didn't open.'"],
	"wardrobe": ["Open the wardrobe", "Empty. Small handprints on the inside of the door, in salt. Scratched low down: 'IT'S ME MUMMY LET ME OUT'."],
	"mirror": ["Look in the mirror", "Just me. Water is running down the inside of the glass."],
	"missing_board": ["Read the notices", "MISSING — dozens of them, nailed over each other. Fishermen, a nurse, two children. Every one says the same thing: 'heard calling from the shore'."],
	"shelter": ["Look inside the shelter", "A bedroll, a tin of beans, a torch with dead batteries. Someone hid here from something. The bedroll is still warm and wet."],
	"bunk": ["Look at the bunk", "A sailor's bunk. A photo of a woman and a baby tucked into the frame. A tin whistle. A letter he never sent."],
	"toys": ["Look at the toys", "A wooden boat, a rag doll, a tin drum. Laid out neatly on the step, as if someone were coming back for them."],
	"church_bell": ["Look at the bell", "Low Vey's warning bell, fallen through the church roof. Barnacles everywhere — except the clapper. That's polished. Worn bright."],
	"cave_names": ["Read the names", "Names scratched into the rock, dozens of them, with dates going back a century. People came in here after voices. The newest one is still wet. E. VALE."],
	"nets": ["Look at the nets", "Fishing nets, still knotted for mending. A child's name stitched into the cork float."],
}

## Documents: id -> [title, body]. Short on purpose; the island does the talking.
const DOCS := {
	"work_order": ["WORK ORDER 7-114 / NORTHERN MARITIME SERVICES",
		"Technician: E. VALE\nSite: Vey Isle coastal weather station (decommissioned)\n\nA distress call is being received from the station on 2.182 MHz. The station has had no power since the island was cleared.\n\n1. Restore station power.\n2. Repair relay array.\n3. Transmit final report and leave.\n\nDo not remain on the island after dark.\n\n(The ink on the last line is fresher than the rest.)"],
	"shed_log": ["DOCK LOG, pinned above the bench",
		"Oct 3 — Someone under the boards again, calling for Peter. There's no Peter on the island. Not since '61.\nOct 9 — My own footsteps came down the dock at 2 a.m. I was in bed.\nOct 11 — Old Wren says never answer. Never.\nOct 12 — Keep the recorder in the shed. Dr. Marrow says if you hear something twice, the first one is the warning."],
	"marrow_echo": ["DR. R. MARROW — FIELD NOTE 41",
		"When we play a recording back, the island returns the sound to the place we took it. Loudly. Every time.\n\nThe tall thing on the lighthouse road walks to it. Twice now it has walked to a sound before the sound was made.\n\nIf you must send it away, give it a sound from somewhere else.\n\nI used to write 'fascinating' at the bottom of these notes. I've stopped."],
	"tea_room": ["Letter, unsent, on the table",
		"Ines —\nMy brother has called me from the shore every night since his boat went down. He sounds cold.\nI've turned the chair to the wall so I won't go to the window. If I answer him, I'll go to him. I know I will.\nThe tea's still warm. Come and sit with me if you can.\n— A."],
	"child_drawing": ["A child's drawing",
		"Crayon on damp paper. The lighthouse, tall and white. Beneath it, a black shape twice as tall as a person, made of scribbled loops like rope.\n\nAt the bottom, in careful letters:\n'THE MAN WHO LISTENS IS WAITING FOR US TO SAY IT'\n\nIn the corner: a small figure with a box in its hand. It has your coat."],
	"safe_ring": ["Note nailed beside the door",
		"WHITE RING = SAFE.\nThe old people painted them for the drowned. It has never come through a door we ringed. Nobody knows why.\nDon't stay longer than you must. It waits outside.\n— Harbourmaster Wren"],
	"wren_customs": ["OLD CUSTOMS OF VEY — as my mother taught them",
		"The sea remembers everyone it takes. Sometimes it gives their voices back.\n\nNever answer a voice from the water after the bell rings.\nIf the bell rings by itself, go indoors.\nIf it rings thirteen times, bar the door and don't sleep.\nPaint a white ring on the threshold. The drowned don't cross it.\nNever follow anyone who calls your name from the dark. It isn't them. It only sounds like them.\n\n— A. Wren, keeper"],
	"wren_key": ["Tag on the station key",
		"WEATHER STATION — COMPOUND GATE.\nKept in the clock. Tomas says it's the only thing in Vey that still keeps time.\n(It runs backwards now. Leave it be.)"],
	"station_manual": ["RELAY ARRAY — OPERATING CARD",
		"Relays A, B and C carry the island signal. Each produces a distinct calibration tone when engaged:\n  A — low\n  B — middle\n  C — high\n\nCorrect sequence is recorded on CALIBRATION TAPE 13 (office).\nAn incorrect sequence trips the station breaker. Wait for the reset."],
	"tape_13": ["Label on the tape deck",
		"CALIBRATION 13 — DO NOT ERASE\n\nUnderneath, in pencil:\n'There is nothing on it but hiss. Ruth says the tones are in there if you listen properly. And footsteps between them. Ruth says the footsteps belong to someone who hasn't come yet.'"],
	"kell_log": ["RADIO LOG — T. KELL",
		"22:41  Carrier from the lighthouse array. The array has no power.\n22:43  Heard my own voice reading this entry.\n22:44  Read this entry.\n23:10  Thirteen seconds of nothing. Not static. Nothing. The gulls stopped.\n23:11  Ruth wants to send a warning out along it.\n23:12  She says it's for whoever comes next."],
	"cave_plaque": ["Stamped brass plate on the iron seal",
		"LOWER GALLERY — RESONANCE SEAL.\nOpens to the note of the TIDE BELL.\nStaff: replay the bell recording into the horn.\nThe bell is in the west niche. It rings when the tide remembers it."],
	"cave_scrawl": ["Scratched into the rock",
		"IT HEARS WHAT YOU'RE GOING TO DO\nTHROW IT SOMETHING ELSE\nTHE PLATE IN THE SIDE CAVE BANGS WHEN THE SEA BREATHES"],
	"landing_note": ["Page torn from a logbook — R. Marrow",
		"Wren told us the drowned bell is the one sound the sea always gives back. So we tuned the transmitter to its note, and every night the lighthouse rang it out over the water.\n\nWe wanted to hear what answered. We did.\n\nIt has been calling ships ever since, in the voices of people they love."],
	"control_note": ["Taped to the seal release lever",
		"The release is the only way down. You'll hear the hatch open before you pull this. Don't let that stop you.\n\nThe couplings below are loud. It goes to the coupling before you touch it. Let it look. Then move.\n— R.M."],
	"keeper_log": ["LIGHTHOUSE LOG — A. Wren, keeper",
		"14 Nov 1923. 02:58. Every sound on the island stopped. The sea, the wind, the fog signal, my own heart. I counted thirteen. Then a bell rang. Not ours. Under the water.\n15 Nov. The sea took Low Vey. The whole lower village, in one tide.\n1968. Admiralty men want to study 'the sounds'. I told them what my father told me: the sea remembers everyone it takes. Don't sit up waiting for it to answer."],
	"wren_1923": ["Diary of Aldo Wren, aged 19 — found in the keeper's cottage",
		"Mother never let us whistle near the water after the bell. The sea learns your sound, she said, and keeps it.\n\nMrs. Ennis heard her drowned boy calling from the slip for seven nights. On the eighth she answered him. We found her door open and her shoes on the shingle.\n\nTonight the whole village can hear it. Every name. Mine too.\n\n14 Nov 1923"],
	"pelagic_brief": ["PROJECT PELAGIC — briefing sheet",
		"Vey Isle, 1968. Lead: Dr. R. Marrow.\nPurpose: investigate reports of voices and other sounds heard at sea near Vey Isle, sometimes before the wrecks and storms that cause them.\nResearch vessel: MV Pelagic.\nThe keeper, A. Wren, declines to help.\nNOTE: the transmitter beneath the light must never be run at full power."],
	"kell_diary_1": ["T. Kell — diary, radio tower hut",
		"I signed up because of my brother's boat. Two years missing. Ruth said if we could hear the sea properly we might hear where they went.\nDay 9 after Morrow's operation. I hear everything. Some of it is my own voice, saying things I haven't said yet.\nDay 23. Light hurts. My hands are getting longer.\nDay 40. I sleep in the rocks by the tower now, upside down. When the bell strikes I go out. Ten minutes. I can't help it."],
	"kell_diary_2": ["T. Kell — last page",
		"I heard my brother tonight, calling from the rocks. It wasn't him. It had his voice the way a shell has the sea.\nMorrow made us hear it. Ruth made the light call it. Between them they woke something.\nI kept my last recording in my nest. With Morrow's tape and the Pelagic's mayday, the transmitter will hear its own silence. That's the only thing that ever made it stop.\nThe tower floodlight still works. Light me up if I come for you. I won't mind."],
	"mayday_log": ["MV PELAGIC — radio log",
		"03:01 A voice on all bands, from the island. Asking for help.\n03:05 Captain sets course for the light. Says he knows the voice. Half the crew say they know it too.\n03:09 Boyd went over the side. He was answering his wife.\n03:10 Men from the annex on deck. Taking the crew below.\n03:12 —"],
	"sailor_letter": ["Letter, never posted — W. Hale, deckhand",
		"Dear Maggie,\nThree more weeks and I'm home. The scientists keep us up all night listening to nothing. Davey swears he heard his gran singing under the hull.\nGive the little one a kiss from her dad.\n— Will\n\nP.S. If I ring and I sound strange, hang up."],
	"missing_notice": ["Notice nailed to a tree",
		"MISSING — have you seen these men?\nJ. ENNIS, R. BOYD, P. MALLORY.\nLast seen entering Blackwood to search for the Pelagic's crew.\nIf you hear them calling you, DO NOT GO.\n— Vey search party, 1971"],
	"shelter_note": ["Pencil on the inside of a tin lid",
		"Day 3 in the woods. Mallory went to the voice by the stream. It was his sister. His sister lives in Leeds.\nI'm staying in the shelter until the bell. If the clicking comes, I don't move.\n— R."],
	"woods_notice": ["Notice at the edge of Blackwood",
		"NO ONE IN THE WOODS WHEN THE BELL STRIKES THE HOUR.\nIf you hear clicking above you, DO NOT MOVE.\nIf someone you lost calls to you from the trees, do not answer.\n— A. Wren"],
	"halloran_letter": ["Letter — Ines Halloran, research assistant",
		"Nell,\nMummy has to go down to the water tonight. Everyone has heard their names.\nI heard yours, love — but you were asleep in your bed, so I know it isn't true.\nKeep the white ring on the door. Don't open it for anyone. Not even if they sound like me.\nI love you."],
	"morrow_file": ["PROJECT MORROW — clinical summary, Dr. E. Morrow",
		"Twelve volunteers, each reporting voices from the sea. Procedure: surgical improvement of hearing. Outcome: excellent. All twelve now hear clearly.\nEleven have since walked into the water.\nSubject 12 (Kell, T.) has changed physically. I no longer record what he says.\nSubject 13 is expected tonight. He will arrive by sea. They always do."],
	"marrow_final": ["R. Marrow — final note, transmitter chamber",
		"I came here to explain the voices. I can't.\nThe sea keeps what it takes — their voices, their footsteps, their last words — and something down there has learned to wear them. It was here before Low Vey drowned. Before the village. We only gave it a louder voice.\nWhoever reads this: break it, send the warning — or let it hear its own silence."],
	"chamber_plate": ["Engraved on the transmitter console",
		"VEY TRANSMITTER\nWith all couplings engaged:\nRED LEVER — OVERLOAD ARRAY (irreversible)\nKEY — TRANSMIT TO MAINLAND"],
}

## Radio transmissions: id -> list of [speaker, line, seconds]. Speech is voiced
## (assets/audio/voice); lines with no speaker are text-only narration.
const RADIO := {
	"boat_arrival": [
		["RADIO", "...Vale. Vale, do you copy...", 3.0],
		["RADIO — YOUR VOICE", "\"Mainland, this is Vale. I'm on the dock. There's nobody here.\"", 4.5],
		["", "(You haven't said that yet.)", 3.0],
	],
	"teahouse": [
		["RADIO — A WOMAN", "\"Did you leave the station key with the clock?\"", 3.5],
		["RADIO — A MAN", "\"Where else? It's the only thing in Vey that keeps time.\"", 4.0],
		["RADIO — A WOMAN", "\"Then go to the blue house and take it before the bell.\"", 4.0],
	],
	"teahouse_echo": [
		["VOICES — FROM THE BLUE HOUSE", "\"...the only thing in Vey that keeps time.\"", 3.5],
	],
	"station_reply": [
		["RADIO", "Report received. Mainland copies, Vey.", 3.5],
		["RADIO — YOUR VOICE", "\"Don't go into the caves. It's already down there. It heard you coming.\"", 5.0],
		["", "(Below the cliffs, the sea is pulling away from the island.)", 4.0],
	],
	"control_voice": [
		["TAPE — YOUR VOICE", "\"Elias. If you're hearing this, you've already chosen once.\"", 4.5],
		["TAPE — YOUR VOICE", "\"Don't listen to the other tape. Whatever it told you—\"", 4.0],
		["", "(The tape ends in thirteen seconds of nothing.)", 4.0],
	],
	"landing_voice": [
		["TAPE — YOUR VOICE", "\"Send it. Whatever it costs. Someone has to know what's out here.\"", 4.5],
		["TAPE — YOUR VOICE", "\"And don't trust the tape upstairs. That one's lying.\"", 4.0],
	],
	"chamber_send": [
		["TRANSMITTER", "Carrier locked. Sending the Vey Isle report to the mainland.", 4.0],
		["RADIO — MAINLAND", "\"Vey, we copy. We... copy.\"", 4.0],
		["", "(Every radio on the island answers at once, in your voice.)", 4.5],
	],
	"suha_1": [
		["RADIO — SUHA", "\"Elias? It's me. Did you land yet? You forgot your scarf again. I'm wearing it, so it's mine now.\"", 5.0],
		["", "(Suha. The radio shouldn't reach that far.)", 3.0],
	],
	"suha_2": [
		["RADIO — SUHA", "\"Hey, it's me again. Remember the ferry, when the lights went out and you said you weren't scared?\"", 5.0],
		["RADIO — SUHA", "\"Be careful out there. Come home soon.\"", 3.5],
	],
	"suha_3": [
		["RADIO — SUHA", "\"Elias. Listen to me. None of this is real. You fell asleep on the boat. You're dreaming.\"", 5.5],
		["RADIO — SUHA", "\"Don't touch that machine. Come up to the top of the lighthouse — to the light. I'm there. I'll wake you up.\"", 6.0],
		["RADIO — SUHA", "\"Come home to me.\"", 3.5],
	],
	"ending_suha": [
		["SUHA", "\"You came. I knew you would. You always come back to me.\"", 4.5],
		["ELIAS", "Suha... I'm so tired. Wake me up.", 3.5],
		["SUHA", "\"Shh. Don't turn the light off. Not ever.\"", 4.0],
		["", "(She turns around.)", 2.5],
		["THE ISLAND — IN HER VOICE", "\"There was never anyone waiting for you, Elias. You drowned at 03:12. We only needed someone to keep the light.\"", 6.5],
	],
	"ending_last": [
		["RADIO", "...", 3.0],
		["", "(Your recorder clicks on by itself. RECORDING 1 OF 1 — 00:13.)", 4.0],
		["", "(Thirteen seconds of nothing. Then, very faintly, someone breathing out.)", 5.0],
	],
	"ending_break": [
		["RADIO", "...", 2.5],
		["RADIO — VERY QUIET", "\"...three more steps.\"", 4.0],
	],
	"ending_send": [
		["RADIO — YOUR VOICE", "\"Mainland, this is Vale. Report sent. I'm leaving the island.\"", 4.5],
		["ELIAS", "Mainland, this is Vale. Report sent. I'm leaving the—", 4.0],
		["RADIO — YOUR VOICE", "\"—it's on the boat.\"", 4.0],
	],
	"dock_name": [
		["A VOICE — UNDER THE DOCK", "\"...Elias...\"", 3.0],
		["A VOICE — UNDER THE DOCK", "\"...Elias, it's cold down here...\"", 4.0],
	],
}

## Recordings: id -> {name, sound, caption}
const RECORDINGS := {
	"dock_steps": {"name": "Footsteps — shed", "sound": "echo_footsteps_voice", "caption": "[footsteps on wood, and a voice beneath them]"},
	"tape_13": {"name": "Calibration tape 13", "sound": "calibration_tape", "caption": "[footsteps on metal... MIDDLE tone... LOW tone... HIGH tone... LOW tone]"},
	"bell": {"name": "Drowned bell", "sound": "bell_drowned", "caption": "[a bell rings underwater]"},
	"plate": {"name": "Loose plate — side cave", "sound": "metal_knock", "caption": "[two heavy metal knocks]"},
	"morrow_tape": {"name": "LAST RECORDING 1/3 — Dr. Morrow", "sound": "voice/rec_morrow_tape", "caption": "[Dr. Morrow: 'Subject Kell can hear the thirteen seconds coming. He says it is not silence. He says it is someone holding their breath.']"},
	"mayday": {"name": "LAST RECORDING 2/3 — Mayday, MV Pelagic", "sound": "voice/rec_mayday", "caption": "[a ship's radio: 'Mayday, Pelagic... we hear the island answering... it is asking us to come closer...']"},
	"kell_tape": {"name": "LAST RECORDING 3/3 — Tomas Kell", "sound": "voice/rec_kell_tape", "caption": "[Kell, in a human voice for the last time: 'If you play all three into the transmitter, it will hear its own silence. Then it will stop calling us.']"},
	"valve": {"name": "Valve knock — chamber", "sound": "metal_knock", "caption": "[a valve hammers twice]"},
	"knocks": {"name": "Three knocks — tea room", "sound": "knock3", "caption": "[three knocks]"},
}
