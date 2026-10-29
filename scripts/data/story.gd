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
	"restore_power": "Restore power to the weather station.",
	"find_sequence": "Find the correct relay sequence. The station office may hold a clue.",
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
	"valve": {"name": "Valve knock — chamber", "sound": "metal_knock", "caption": "[a valve hammers twice]"},
	"knocks": {"name": "Three knocks — tea room", "sound": "knock3", "caption": "[three knocks]"},
}
