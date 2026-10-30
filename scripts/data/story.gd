class_name Story
## All written content: objectives, documents, radio transmissions and the
## recordings the field recorder can capture. Kept in one place so tone and
## facts stay consistent.

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
	"activate_transmitter": "Transmit the diagnostic report from the monitoring room.",
	"find_caves": "The tide is out. Find the exposed caves below the east cliffs.",
	"open_gate": "Open the acoustic seal in the caves.",
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
	["ch_dock", "I", "THE FLOODED DOCK", "You are Elias Vale, a technician sent to restore a dead weather station. The island was expecting you."],
	["ch_settlement", "II", "THE SETTLEMENT", "Forty people lived here. They left their tea on the table."],
	["ch_station", "III", "THE WEATHER STATION", "Project Pelagic listened to the sea from here. It still sends a distress call."],
	["ch_forest", "IV", "BLACKWOOD", "Tomas Kell listened longer than anyone. He still lives out here, after a fashion."],
	["ch_graveyard", "V", "THE SHIP GRAVEYARD", "Every ship that answered the island's call is still here."],
	["ch_lowvey", "VI", "LOW VEY", "The village the sea took in 1923. Tonight the tide has given it back."],
	["ch_caves", "VII", "THE TIDAL CAVES", "The researchers sealed these caves. Something was waiting under the water."],
	["ch_annex", "VIII", "THE ANNEX", "Project Morrow. Where they taught people to hear the future."],
	["ch_lighthouse", "IX", "THE LIGHTHOUSE", "The light has been listening all night."],
	["ch_chamber", "X", "WHAT THE TIDE REMEMBERS", "Every sound you heard tonight came from here."],
]

## Elias's notebook [J]: what he has worked out, in plain words. [flag, title, text]
const JOURNAL := [
	["j_arrival", "Why I'm here", "Northern Maritime sent me to Vey Isle to restore the old weather station and transmit its final report. The station has been sending a distress call for years with no power. On the boat, the radio played MY voice, saying words I hadn't said yet."],
	["j_preecho", "Pre-echoes", "On this island some sounds arrive BEFORE the thing that makes them. I heard my own footsteps on the dock before I walked there. The researchers called these pre-echoes. The recorder hears them better when I listen [Q]."],
	["j_replay", "The recorder", "If I record a sound and replay it, the island sends that sound back to the place I recorded it — loudly. I can use that to lure things away from me. But the recorder's own speaker can be heard too."],
	["j_listener", "The Listener", "Something walks the island: a tall shape of soaked rope, fishing net and ship parts. It goes to sounds — even sounds that haven't happened yet. It sees badly: crouching and switching off my light helps. It never goes through a doorway, and never into a room with a WHITE RING on the door."],
	["j_key", "The station key", "The radio told me where the key was before I found it: in the blue house, inside a clock that runs backwards."],
	["j_station", "Project Pelagic", "The station belonged to Project Pelagic — a 1960s experiment to predict storms and shipwrecks by listening to the sea. They found sounds that arrived before their causes. Kell, the radio operator, logged hearing his own voice before he spoke."],
	["j_tide", "The tide", "When I sent the report, the sea pulled back from the island. The radio — in my voice — warned me not to go into the caves. The old village of Low Vey is lying out on the shore, exposed."],
	["j_lowvey", "Low Vey", "Low Vey drowned in 1923. The night before the storm, every sound on the island stopped for thirteen seconds. That silence is what Pelagic was built to find again. I just lived through it."],
	["j_morrow", "Project Morrow", "Under the caves: Project Morrow, Dr. Edwin Morrow's medical annex. They operated on volunteers' ears so people could hear pre-echoes themselves. Tomas Kell was the last subject. My name is on their list of future subjects."],
	["j_kell", "Tomas Kell", "Kell lives in Blackwood now, changed: long arms, wings of skin, he hunts by clicking like a bat. He sleeps in a rock cave by the old radio tower and comes out only when the bell strikes the hour [T: watch]. If his clicks pass over me I must not move. Light hurts him."],
	["j_pelagic", "The missing ships", "The research ship MV Pelagic and the boats that came looking for her are wrecked on the west shore. Their crews heard the island 'asking them to come closer'."],
	["j_last", "The last recording", "Kell left a message: three recordings together — Morrow's tape, the Pelagic mayday and his own — would let the transmitter 'hear itself' and stop listening to us. I can play them in the chamber."],
	["j_truth", "What is happening", "Marrow's notes make it clear. The transmitter under the lighthouse listens to sounds from the future. It heard thirteen seconds of the island going silent — and something ANSWERED. The Listener is how that something hears us. What it is, nobody wrote down."],
	["j_choice", "The choice", "In the chamber I can OVERLOAD the transmitter (the loop ends; the warning is never sent), or TRANSMIT the report (the mainland is warned of what's coming, but the signal goes with it)."],
]

## Elias's spoken thoughts (subtitled as ELIAS). id -> line
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
	"station": "Project Pelagic. Let's get the lights on and get out.",
	"tide_out": "The sea is pulling away from the island. That isn't possible.",
	"forest": "Something is clicking up in the trees.",
	"cabin": "The radio tower hut. Kell's. Tally marks on every wall — hours.",
	"roost": "He's up there. Hanging. Breathing like a man asleep.",
	"kell_wakes": "He's awake! The tower floodlight — light hurts him!",
	"kell_dead": "In the light he looked like a man again. I'm sorry, Tomas.",
	"graveyard": "The Pelagic. And every boat that came looking for her.",
	"cargo": "Oh God. They kept the crew in the hold.",
	"lowvey": "Low Vey. The drowned village. The tide brought it back.",
	"silence": "...",
	"caves": "The caves the radio warned me about. Of course I'm going in.",
	"annex": "A hospital. Under the sea.",
	"exam": "They were cutting into people's ears. To make them hear better.",
	"lighthouse": "Two tapes, both in my voice, telling me opposite things.",
	"chamber": "This is it. This is what's been listening.",
	"lodger": "...Who's there?",
}

## Things to examine: id -> [prompt, Elias's comment]
const EXAMINE := {
	"boat_engine": ["Examine the engine", "The diesel is still warm. I'm the only one who's been on this boat tonight. I think."],
	"shed_photo": ["Look at the photograph", "The Pelagic team in front of the lighthouse, 1971. Every face is scratched out except one, at the back. He's wearing my coat."],
	"teahouse_cup": ["Look at the teacup", "Still steaming. Lipstick on the rim — and a year of dust on the saucer."],
	"teahouse_chair": ["Look at the chair", "Someone sat facing the wall. There are nail marks in the plaster where they held on."],
	"blue_bed": ["Look at the bed", "Nell Halloran's bed. The blanket is soaked and smells of the sea."],
	"office_map": ["Study the wall map", "Red pins where people vanished. They make a path from the dock to the lighthouse."],
	"station_board": ["Read the chalkboard", "'HOURS SINCE THE 13 SECONDS: 4,117.' The count stopped years ago. The chalk is fresh."],
	"cabin_radio": ["Look at the radio rig", "Built from station parts and aimed at the lighthouse. Scratched on the dial: 'IT TALKS BACK'."],
	"cabin_mirror": ["Look in the mirror", "Painted over. Written in the paint from the inside: 'I DON'T LOOK LIKE ME'."],
	"forest_remains": ["Look closer", "Wrapped in fishing net and hung up like a catch. Whoever it was, the Listener kept them."],
	"ship_radio": ["Examine the radio", "The Pelagic's radio. The valves are glowing. There's no battery."],
	"cargo_net": ["Look at the net", "A cargo net full of... crew. Their ears are gone. Cut away neatly."],
	"lowvey_table": ["Look at the table", "A family at supper, under fifty years of sea. Their heads are all turned the same way. Toward the lighthouse."],
	"annex_jars": ["Look at the jars", "Human ears in formalin. Labelled by date. Some of the dates are next year."],
	"annex_chair": ["Look at the chair", "A dentist's chair with straps, and a headset bolted into the bone of whoever sat here."],
	"annex_list": ["Read the subject list", "SUBJECTS 1–12, crossed out. SUBJECT 13: E. VALE — 'arrives by sea'. That's me."],
	"chamber_dial": ["Look at the dials", "Every needle points at the same time: 03:12."],
}

## Documents: id -> [title, body]. Short on purpose; the island does the talking.
const DOCS := {
	"work_order": ["WORK ORDER 7-114 / NORTHERN MARITIME SERVICES",
		"Technician: E. VALE\nSite: Vey Isle coastal weather station (decommissioned)\n\nA distress carrier is being received from the station on 2.182 MHz. The station has had no power supply since the settlement was cleared.\n\n1. Restore station power.\n2. Repair relay array.\n3. Transmit final diagnostic report and leave.\n\nDo not remain on the island after dark.\n\n(The ink on the last line is fresher than the rest.)"],
	"shed_log": ["DOCK LOG, pinned above the bench",
		"Oct 3 — Ferry turned back again. Captain says his radio read our call before we made it.\nOct 9 — Heard the boat land at 2 a.m. Went down with a lamp. No boat.\nOct 11 — The boat landed at 2 a.m. Just like I heard.\nOct 12 — Keep the recorder in the shed. Dr. Marrow says if you hear something twice, the first one is the warning."],
	"marrow_echo": ["DR. R. MARROW — FIELD NOTE 41",
		"Replayed the dock tape in the lab. Tomas was standing on the dock at the time and swears he heard it there, not here.\n\nThe island returns a sound to the place it was recorded. Every time.\n\nIt also follows whatever it hears. Twice now it has walked to a sound before the sound was made.\n\nTold everyone: if you must distract it, give it a sound from somewhere else."],
	"tea_room": ["Letter, unsent, on the table",
		"Ines —\nI've turned the chair to the wall. If I can't see the window I can't see it standing under the light, and if I can't see it maybe it can't hear me looking.\nThe tea is still warm. I made it tomorrow.\n— A."],
	"child_drawing": ["A child's drawing",
		"Crayon on damp paper. The lighthouse, tall and white. Beneath it, a black shape twice as tall as a person, made of scribbled loops like rope.\n\nAt the bottom, in careful letters:\n'THE MAN WHO LISTENS IS WAITING FOR US TO SAY IT'\n\nIn the corner: a small figure with a box in its hand. It has your coat."],
	"safe_ring": ["Note nailed beside the door",
		"WHITE RING = SAFE.\nIt has never come through a door we ringed. Nobody knows why.\nDon't stay longer than you must. It waits outside.\n— Harbourmaster Wren"],
	"wren_key": ["Tag on the station key",
		"WEATHER STATION — COMPOUND GATE.\nKept in the clock. Tomas says it's the only thing in Vey that still keeps time.\n(It runs backwards now. Leave it be.)"],
	"station_manual": ["RELAY ARRAY — OPERATING CARD",
		"Relays A, B and C carry the island signal. Each produces a distinct calibration tone when engaged:\n  A — low\n  B — middle\n  C — high\n\nCorrect sequence is recorded on CALIBRATION TAPE 13 (office).\nAn incorrect sequence trips the station breaker. Wait for the reset.\n\nDO NOT run the sequence twice in one night."],
	"tape_13": ["Label on the tape deck",
		"CALIBRATION 13 — DO NOT ERASE\n\nUnderneath, in pencil:\n'There is nothing on it but hiss. Ruth says the tones are in there if you listen properly. Ruth says they're in the order we haven't pressed them yet. Ruth says the footsteps between them belong to someone who hasn't arrived.'"],
	"kell_log": ["RADIO LOG — T. KELL",
		"22:41  Received carrier from the lighthouse array. Power to the array was cut in March.\n22:43  Received my own voice reading this entry.\n22:44  Read this entry.\n23:10  Received 13 seconds of nothing. Not static. Nothing. The birds stopped while it played.\n23:11  Ruth wants to transmit a warning back along it. I told her you can't warn the past.\n23:12  She said we aren't. We're warning whoever comes next."],
	"cave_plaque": ["Stamped brass plate on the iron seal",
		"VEY ACOUSTIC SURVEY — LOWER GALLERY\nRESONANCE SEAL. Opens to the TIDE BELL (310 Hz).\nStaff: replay the bell recording into the horn.\nThe bell is in the west niche. It rings when the tide remembers it."],
	"cave_scrawl": ["Scratched into the rock",
		"IT HEARS WHAT YOU'RE GOING TO DO\nTHROW IT SOMETHING ELSE\nTHE PLATE IN THE SIDE CAVE BANGS WHEN THE SEA BREATHES"],
	"landing_note": ["Page torn from a logbook — R. Marrow",
		"The thirteen seconds were not a recording of the island going silent. They were a recording of the island being SPOKEN TO. Something answered.\n\nThe transmitter listens down there. The Listener walks for it. Every sound it hunts is a sound the island has not made yet.\n\nIf we break it, the loop closes and nothing gets out. If we send the warning, they will know on the mainland — and so will it."],
	"control_note": ["Taped to the seal release lever",
		"The release is the only way down. You'll hear the hatch open before you pull this. Don't let that stop you.\n\nThe couplings below are loud. It goes to the coupling before you touch it. Let it look. Then move.\n— R.M."],
	"keeper_log": ["LIGHTHOUSE LOG — A. Wren, keeper",
		"14 Nov 1923. 02:58. Every sound on the island stopped. The sea, the wind, the fog signal, my own heart. I counted thirteen.\n15 Nov. The storm took Low Vey. The whole lower village, in one tide.\n1968. The Pelagic people want to listen for 'the thirteen seconds' again. I told them some things you should not wait up for."],
	"pelagic_brief": ["PROJECT PELAGIC — briefing sheet",
		"Admiralty early-warning research, Vey Isle, 1968–71. Lead: Dr. R. Marrow.\nObjective: predict storms and wrecks by detecting 'pre-acoustic' signals that precede their causes.\nResearch vessel: MV Pelagic.\nNOTE: the transmitter beneath the light must never be run at full gain."],
	"kell_diary_1": ["T. Kell — diary, radio tower hut",
		"Day 9 after the operation. I can hear the shape of the room with my eyes shut. I click my tongue and the walls answer.\nDay 14. Light hurts. I keep the lamp off.\nDay 23. My hands are getting longer.\nDay 40. I sleep in the rocks by the tower now, upside down, the way they do. I only go out when the bell strikes the hour. I can't stop myself. Ten minutes, then back."],
	"kell_diary_2": ["T. Kell — last page",
		"Morrow made us listen. Marrow made the island speak. Between them they woke something.\nI kept my last recording in my nest. With Morrow's tape and the Pelagic's mayday it will let the transmitter hear itself. That's the only thing that ever made it stop.\nThe tower floodlight still works. Light me up if I come for you. I won't mind."],
	"mayday_log": ["MV PELAGIC — radio log",
		"03:01 Island signal received on all bands.\n03:05 Captain orders course for the light. Says it is asking us to come closer.\n03:09 Crew below. Ears bleeding. Morrow's people are 'collecting'.\n03:12 —"],
	"halloran_letter": ["Letter — Ines Halloran, research assistant",
		"Nell,\nIf you find this, Mummy has gone down to the water with the others. Dr. Marrow says it doesn't hurt. Dr. Morrow says it is an honour to be heard.\nKeep the white ring on the door. It won't come in. I love you."],
	"morrow_file": ["PROJECT MORROW — clinical summary, Dr. E. Morrow",
		"Twelve volunteers received cochlear grafts tuned to the transmitter's carrier. All twelve began to hear pre-echoes. Eleven are no longer present.\nSubject 12 (Kell, T.) shows remarkable physical adaptation.\nSubject 13 is expected tonight. He will arrive by sea. He always does."],
	"marrow_final": ["R. Marrow — final note, transmitter chamber",
		"We were never listening to the future. The future was listening to us — and it learned to answer. The Listener is its ear on the island. What it is, I could not tell you. It was here before Low Vey drowned.\nWhoever reads this: you have three choices, not two. Break it. Send the warning. Or let it hear itself."],
	"chamber_plate": ["Engraved on the transmitter console",
		"VEY PRE-ACOUSTIC TRANSMITTER\nWith all couplings engaged:\nRED LEVER — OVERLOAD ARRAY (irreversible)\nKEY — TRANSMIT TO MAINLAND"],
}

## Radio transmissions: id -> list of [speaker, line, seconds]. Spoken lines are
## shown as radio text; the audio underneath is distorted, unintelligible voice.
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
		["RADIO", "Diagnostic report received. Mainland copies, Vey.", 3.5],
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
}

## Recordings: id -> {name, sound, caption}
const RECORDINGS := {
	"dock_steps": {"name": "Footsteps — shed", "sound": "echo_footsteps_voice", "caption": "[footsteps on wood, and a voice beneath them]"},
	"tape_13": {"name": "Calibration tape 13", "sound": "calibration_tape", "caption": "[footsteps on metal... MIDDLE tone... LOW tone... HIGH tone... LOW tone]"},
	"bell": {"name": "Drowned bell", "sound": "bell_drowned", "caption": "[a bell rings underwater]"},
	"plate": {"name": "Loose plate — side cave", "sound": "metal_knock", "caption": "[two heavy metal knocks]"},
	"morrow_tape": {"name": "LAST RECORDING 1/3 — Dr. Morrow", "sound": "radio_voice_c", "caption": "[Dr. Morrow: 'Subject Kell can hear the thirteen seconds coming. He says it is not silence. He says it is someone holding their breath.']"},
	"mayday": {"name": "LAST RECORDING 2/3 — Mayday, MV Pelagic", "sound": "radio_voice_d", "caption": "[a ship's radio: 'Mayday, Pelagic... we hear the island answering... it is asking us to come closer...']"},
	"kell_tape": {"name": "LAST RECORDING 3/3 — Tomas Kell", "sound": "radio_voice_a", "caption": "[Kell, in a human voice for the last time: 'If you play all three into the transmitter, it will hear itself. Then it will stop listening to us.']"},
	"valve": {"name": "Valve knock — chamber", "sound": "metal_knock", "caption": "[a valve hammers twice]"},
	"knocks": {"name": "Three knocks — tea room", "sound": "knock3", "caption": "[three knocks]"},
}
