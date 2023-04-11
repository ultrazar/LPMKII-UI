extends HBoxContainer


const stageLabelDictionary = [
	"Stage 1 (Phase 2) - configuration",
	"Stage 2 (Phase 1) - ascend and descend",
	"Stage 3 (Phase 2) - Stationed control"
]

func updatePanel():
	$VBoxContainer/name/SessionName.text = SessionData.sessionName
	$VBoxContainer/directory/SessionDirectory.text = SessionData.sessionDirectoryPath
	$VBoxContainer/stageLabel.text = "Session state: " + stageLabelDictionary[SessionData.stage]
	$VBoxContainer/stage/S1.modulate = Color("ffffff") if SessionData.stage == SessionData.STAGE_1 else Color("808080")
	$VBoxContainer/stage/S2.modulate = Color("ffffff") if SessionData.stage == SessionData.STAGE_2 else Color("808080")
	$VBoxContainer/stage/S3.modulate = Color("ffffff") if SessionData.stage == SessionData.STAGE_3 else Color("808080")
	
