'Required for statistical purposes==========================================================================================
name_of_script = "CA - APPLICATION RECEIVED.vbs"
start_time = timer
STATS_counter = 1                          'sets the stats counter at one
STATS_manualtime = 500                     'manual run time in seconds
STATS_denomination = "C"                   'C is for each CASE
'END OF stats block=========================================================================================================

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN	   'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF use_master_branch = TRUE THEN			   'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/Hennepin-County/MAXIS-scripts/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else											'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/Hennepin-County/MAXIS-scripts/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		End if
		SET req = CreateObject("Msxml2.XMLHttp.6.0")				'Creates an object to get a FuncLib_URL
		req.open "GET", FuncLib_URL, FALSE							'Attempts to open the FuncLib_URL
		req.send													'Sends request
		IF req.Status = 200 THEN									'200 means great success
			Set fso = CreateObject("Scripting.FileSystemObject")	'Creates an FSO
			Execute req.responseText								'Executes the script code
		ELSE														'Error message
			critical_error_msgbox = MsgBox ("Something has gone wrong. The Functions Library code stored on GitHub was not able to be reached." & vbNewLine & vbNewLine &_
                                            "FuncLib URL: " & FuncLib_URL & vbNewLine & vbNewLine &_
                                            "The script has stopped. Please check your Internet connection. Consult a scripts administrator with any questions.", _
                                            vbOKonly + vbCritical, "BlueZone Scripts Critical Error")
            StopScript
		END IF
	ELSE
		FuncLib_URL = "C:\MAXIS-scripts\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================

'CHANGELOG BLOCK ===========================================================================================================
'Starts by defining a changelog array
changelog = array()

'INSERT ACTUAL CHANGES HERE, WITH PARAMETERS DATE, DESCRIPTION, AND SCRIPTWRITER. **ENSURE THE MOST RECENT CHANGE GOES ON TOP!!**
'Example: call changelog_update("01/01/2000", "The script has been updated to fix a typo on the initial dialog.", "Jane Public, Oak County")
CALL changelog_update("11/15/2018", "Enhanced functionality for SameDay interview cases.", "Casey Love, Hennepin County")
CALL changelog_update("11/06/2018", "Updated handling for HC only applications.", "MiKayla Handley, Hennepin County")
CALL changelog_update("10/25/2018", "Updated script to add handling for case correction.", "MiKayla Handley, Hennepin County")
CALL changelog_update("10/17/2018", "Updated appointment letter to address EGA programs.", "MiKayla Handley, Hennepin County")
CALL changelog_update("09/01/2018", "Updated Utility standards that go into effect for 10/01/2018.", "Ilse Ferris, Hennepin County")
CALL changelog_update("07/20/2018", "Changed wording of the Appointment Notice and changed default interview date to 10 days from application for non-expedidted cases.", "Casey Love, Hennepin County")
CALL changelog_update("07/16/2018", "BUg Fix that was preventing notices from being sent.", "Casey Love, Hennepin County")
CALL changelog_update("03/28/2018", "Updated appt letter case note for bulk script process.", "MiKayla Handley, Hennepin County")
CALL changelog_update("02/21/2018", "Added on demand waiver handling.", "MiKayla Handley, Hennepin County")
CALL changelog_update("02/16/2018", "Added case transfer confirmation coding.", "Ilse Ferris, Hennepin County")
CALL changelog_update("12/29/2017", "Coordinates for sending MEMO's has changed in SPEC/MEMO. Updated script to support change.", "Ilse Ferris, Hennepin County")
CALL changelog_update("11/03/2017", "Email functionality - only expedited emails will be sent to Triagers.", "Ilse Ferris, Hennepin County")
CALL changelog_update("10/25/2017", "Email functionality - will create email, and send for all CASH and FS applications.", "MiKayla Handley, Hennepin County")
CALL changelog_update("10/12/2017", "Email functionality will create email, but not send it. Staff will need to send email after reviewing email.", "Ilse Ferris, Hennepin County")
CALL changelog_update("08/07/2017", "Initial version.", "MiKayla Handley, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'---------------------------------------------------------------------------------------The script
'Grabs the case number
EMConnect ""
CALL MAXIS_case_number_finder (MAXIS_case_number)

'-------------------------------------------------------------------------------------------------DIALOG
BeginDialog initial_dialog, 0, 0, 116, 45, "Application Received"
  EditBox 65, 5, 45, 15, MAXIS_case_number
  ButtonGroup ButtonPressed
    OkButton 5, 25, 50, 15
    CancelButton 60, 25, 50, 15
  Text 10, 10, 50, 10, "Case Number:"
EndDialog

'Runs the first dialog - which confirms the case number
Do
	Do
		err_msg = ""
		Dialog initial_dialog
		cancel_confirmation
		IF MAXIS_case_number = "" or IsNumeric(MAXIS_case_number) = False or len(MAXIS_case_number) > 8 then err_msg = err_msg & vbNewLine & "* Enter a valid case number."
		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
	LOOP UNTIL err_msg = ""
CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
LOOP UNTIL are_we_passworded_out = false					'loops until user passwords back in

'----------------------------------------------------------------------------------------------------'pending & active programs information
'information gathering to auto-populate the application date
back_to_self
EMWriteScreen MAXIS_case_number, 18, 43
Call navigate_to_MAXIS_screen("REPT", "PND2")

'Ensuring that the user is in REPT/PND2
Do
	EMReadScreen PND2_check, 4, 2, 52
	If PND2_check <> "PND2" then
		back_to_SELF
		Call navigate_to_MAXIS_screen("REPT", "PND2")
	End if
LOOP until PND2_check = "PND2"

'checking the case to make sure there is a pending case.  If not script will end & inform the user no pending case exists in PND2
EMReadScreen not_pending_check, 5, 24, 2
If not_pending_check = "CASE " THEN script_end_procedure("There is not a pending program on this case, or case is not in PND2 status." & vbNewLine & vbNewLine & "Please make sure you have the right case number, and/or check your case notes to ensure that this application has been completed.")

'grabs row and col number that the cursor is at
EMGetCursor MAXIS_row, MAXIS_col
EMReadScreen app_month, 2, MAXIS_row, 38
EMReadScreen app_day, 2, MAXIS_row, 41
EMReadScreen app_year, 2, MAXIS_row, 44
EMReadScreen days_pending, 3, MAXIS_row, 50
EMReadScreen additional_application_check, 14, MAXIS_row + 1, 17
EMReadScreen add_app_month, 2, MAXIS_row + 1, 38
EMReadScreen add_app_day, 2, MAXIS_row + 1, 41
EMReadScreen add_app_year, 2, MAXIS_row + 1, 44

'Creating new variable for application check date and additional application date.
application_date = app_month & "/" & app_day & "/" & app_year
additional_application_date = add_app_month & "/" & add_app_day & "/" & add_app_year

'checking for multiple application dates.  Creates message boxes giving the user an option of which app date to choose
If additional_application_check = "ADDITIONAL APP" THEN multiple_apps = MsgBox("Do you want this application date: " & application_date, VbYesNoCancel)
If multiple_apps = vbCancel then stopscript
If multiple_apps = vbYes then application_date = application_date
IF multiple_apps = vbNo then
	additional_apps = Msgbox("Do you want this application date: " & additional_application_date, VbYesNoCancel)
	application_date = ""
	If additional_apps = vbCancel then stopscript
	If additional_apps = vbNo then script_end_procedure("No more application dates exist. Please review the case, and start the script again if applicable.")
	If additional_apps = vbYes then
		additional_date_found = TRUE
		application_date = additional_application_date
END IF
End if

MAXIS_footer_month = right("00" & DatePart("m", application_date), 2)
MAXIS_footer_year = right(DatePart("yyyy", application_date), 2)

CALL navigate_to_MAXIS_screen("STAT", "PROG")		'Goes to STAT/PROG
'EMReadScreen application_date, 8, 6, 33

EMReadScreen err_msg, 7, 24, 02
IF err_msg = "BENEFIT" THEN	script_end_procedure ("Case must be in PEND II status for script to run, please update MAXIS panels TYPE & PROG (HCRE for HC) and run the script again.")

'Reading the app date from PROG
EMReadScreen cash1_app_date, 8, 6, 33
cash1_app_date = replace(cash1_app_date, " ", "/")
EMReadScreen cash2_app_date, 8, 7, 33
cash2_app_date = replace(cash2_app_date, " ", "/")
EMReadScreen emer_app_date, 8, 8, 33
emer_app_date = replace(emer_app_date, " ", "/")
EMReadScreen grh_app_date, 8, 9, 33
grh_app_date = replace(grh_app_date, " ", "/")
EMReadScreen snap_app_date, 8, 10, 33
snap_app_date = replace(snap_app_date, " ", "/")
EMReadScreen ive_app_date, 8, 11, 33
ive_app_date = replace(ive_app_date, " ", "/")
EMReadScreen hc_app_date, 8, 12, 33
hc_app_date = replace(hc_app_date, " ", "/")
EMReadScreen cca_app_date, 8, 14, 33
cca_app_date = replace(cca_app_date, " ", "/")

'Reading the program status
EMReadScreen cash1_status_check, 4, 6, 74
EMReadScreen cash2_status_check, 4, 7, 74
EMReadScreen emer_status_check, 4, 8, 74
EMReadScreen grh_status_check, 4, 9, 74
EMReadScreen snap_status_check, 4, 10, 74
EMReadScreen ive_status_check, 4, 11, 74
EMReadScreen hc_status_check, 4, 12, 74
EMReadScreen cca_status_check, 4, 14, 74

'----------------------------------------------------------------------------------------------------ACTIVE program coding
EMReadScreen cash1_prog_check, 2, 6, 67     'Reading cash 1
EMReadScreen cash2_prog_check, 2, 7, 67     'Reading cash 2
EMReadScreen emer_prog_check, 2, 8, 67      'EMER Program

'Logic to determine if MFIP is active
IF cash1_prog_check = "MF" or cash1_prog_check = "GA" or cash1_prog_check = "DW" or cash1_prog_check = "MS" THEN
	IF cash1_status_check = "ACTV" THEN cash_active = TRUE
END IF
IF cash2_prog_check = "MF" or cash2_prog_check = "GA" or cash2_prog_check = "DW" or cash2_prog_check = "MS" THEN
	IF cash2_status_check = "ACTV" THEN cash2_active = TRUE
END IF
IF emer_prog_check = "EG" and emer_status_check = "ACTV" THEN emer_active = TRUE
IF emer_prog_check = "EA" and emer_status_check = "ACTV" THEN emer_active = TRUE

IF cash1_status_check = "ACTV" THEN cash_active  = TRUE
IF cash2_status_check = "ACTV" THEN cash2_active = TRUE
IF snap_status_check  = "ACTV" THEN SNAP_active  = TRUE
IF grh_status_check   = "ACTV" THEN grh_active   = TRUE
IF ive_status_check   = "ACTV" THEN IVE_active   = TRUE
IF hc_status_check    = "ACTV" THEN hc_active    = TRUE
IF cca_status_check   = "ACTV" THEN cca_active   = TRUE

active_programs = ""        'Creates a variable that lists all the active.
IF cash_active = TRUE or cash2_active = TRUE THEN active_programs = active_programs & "CASH, "
IF emer_active = TRUE THEN active_programs = active_programs & "Emergency, "
IF grh_active  = TRUE THEN active_programs = active_programs & "GRH, "
IF snap_active = TRUE THEN active_programs = active_programs & "SNAP, "
IF ive_active  = TRUE THEN active_programs = active_programs & "IV-E, "
IF hc_active   = TRUE THEN active_programs = active_programs & "HC, "
IF cca_active  = TRUE THEN active_programs = active_programs & "CCA"

active_programs = trim(active_programs)  'trims excess spaces of active_programs
If right(active_programs, 1) = "," THEN active_programs = left(active_programs, len(active_programs) - 1)

'----------------------------------------------------------------------------------------------------Pending programs
programs_applied_for = ""   'Creates a variable that lists all pening cases.
additional_programs_applied_for = ""
'cash I
IF cash1_status_check = "PEND" then
    If cash1_app_date = application_date THEN
        cash_pends = TRUE
        programs_applied_for = programs_applied_for & "CASH, "
    Else
        additional_programs_applied_for = additional_programs_applied_for & "CASH, "
    End if
End if
'cash II
IF cash2_status_check = "PEND" then
    if cash2_app_date = application_date THEN
        cash2_pends = TRUE
        programs_applied_for = programs_applied_for & "CASH, "
    Else
        additional_programs_applied_for = additional_programs_applied_for & "CASH, "
    End if
End if
'SNAP
IF snap_status_check  = "PEND" then
    If snap_app_date  = application_date THEN
        SNAP_pends = TRUE
        programs_applied_for = programs_applied_for & "SNAP, "
    else
        additional_programs_applied_for = additional_programs_applied_for & "SNAP, "
    end if
End if
'GRH
IF grh_status_check = "PEND" then
    If grh_app_date = application_date THEN
        grh_pends = TRUE
        programs_applied_for = programs_applied_for & "GRH, "
    else
        additional_programs_applied_for = additional_programs_applied_for & "GRH, "
    End if
End if
'I-VE
IF ive_status_check = "PEND" then
    if ive_app_date = application_date THEN
        IVE_pends = TRUE
        programs_applied_for = programs_applied_for & "IV-E, "
    else
        additional_programs_applied_for = additional_programs_applied_for & "IV-E, "
    End if
End if
'HC
IF hc_status_check = "PEND" then
    If hc_app_date = application_date THEN
        hc_pends = TRUE
        programs_applied_for = programs_applied_for & "HC, "
    else
        additional_programs_applied_for = additional_programs_applied_for & "HC, "
    End if
End if
'CCA
IF cca_status_check = "PEND" then
    If cca_app_date = application_date THEN
        cca_pends = TRUE
        programs_applied_for = programs_applied_for & "CCA, "
    else
        additional_programs_applied_for = additional_programs_applied_for & "CCA, "
    End if
End if
'EMER
If emer_status_check = "PEND" then
    If emer_app_date = application_date then
        emer_pends = TRUE
        IF emer_prog_check = "EG" THEN programs_applied_for = programs_applied_for & "EGA, "
        IF emer_prog_check = "EA" THEN programs_applied_for = programs_applied_for & "EA, "
    else
        IF emer_prog_check = "EG" THEN additional_programs_applied_for = additional_programs_applied_for & "EGA, "
        IF emer_prog_check = "EA" THEN additional_programs_applied_for = additional_programs_applied_for & "EA, "
    End if
End if

programs_applied_for = trim(programs_applied_for)       'trims excess spaces of programs_applied_for
If right(programs_applied_for, 1) = "," THEN programs_applied_for = left(programs_applied_for, len(programs_applied_for) - 1)

additional_programs_applied_for = trim(additional_programs_applied_for)       'trims excess spaces of programs_applied_for
If right(additional_programs_applied_for, 1) = "," THEN additional_programs_applied_for = left(additional_programs_applied_for, len(additional_programs_applied_for) - 1)

'----------------------------------------------------------------------------------------------------dialogs
BeginDialog appl_detail_dialog, 0, 0, 296, 170, "Application Received for: " & programs_applied_for
  DropListBox 90, 10, 65, 15, "Select One:"+chr(9)+"Fax"+chr(9)+"Mail"+chr(9)+"Office"+chr(9)+"Online", how_app_rcvd
  DropListBox 90, 30, 65, 15, "Select One:"+chr(9)+"ApplyMN"+chr(9)+"CAF"+chr(9)+"6696"+chr(9)+"HCAPP"+chr(9)+"HC-Certain Pop"+chr(9)+"LTC"+chr(9)+"MHCP B/C Cancer", app_type
  EditBox 230, 30, 55, 15, confirmation_number
  EditBox 55, 90, 20, 15, transfer_case_number
  CheckBox 75, 110, 155, 10, "Check if the case does not require a transfer ", no_transfer_check
  EditBox 55, 130, 235, 15, other_notes
  EditBox 75, 150, 105, 15, worker_signature
  ButtonGroup ButtonPressed
    OkButton 185, 150, 50, 15
    CancelButton 240, 150, 50, 15
    PushButton 230, 90, 55, 15, "GeoCoder", geocoder_button
  Text 160, 15, 125, 10, "Date of Application: "  & application_date
  Text 20, 35, 65, 10, "Type of Application:"
  Text 175, 35, 50, 10, "Confirmation #:"
  Text 15, 95, 40, 10, "Transfer to:"
  Text 85, 95, 135, 10, "(last 3 digit of X#) transfer case to basket"
  Text 10, 135, 45, 10, "Other Notes:"
  Text 10, 155, 60, 10, "Worker Signature:"
  GroupBox 5, 80, 285, 45, "Transfer Information"
  Text 15, 15, 70, 10, "Application Received:"
  GroupBox 5, 0, 285, 80, "Application Information"
  CheckBox 10, 50, 115, 10, "Check if this is a case correction", case_correction
  EditBox 230, 50, 55, 15, requested_person
  Text 160, 55, 65, 10, "Requesting person:"
  CheckBox 10, 65, 150, 10, "Check if this is a MNSURE Retro Request", mnsure_retro_checkbox
EndDialog

'------------------------------------------------------------------------------------DIALOG APPL
    Do
    	Do
			err_msg = ""
		Do
    		Dialog appl_detail_dialog
    		cancel_confirmation
			If ButtonPressed = geocoder_button then CreateObject("WScript.Shell").Run("https://hcgis.hennepin.us/agsinteractivegeocoder/default.aspx")
		Loop until ButtonPressed = -1
    		IF how_app_rcvd = "Select One:" then err_msg = err_msg & vbNewLine & "* Please enter how the application was received to the agency."
		IF how_app_rcvd = "Online" and app_type <> "ApplyMN" then err_msg = err_msg & vbNewLine & "* You selected that the application was received online please select ApplyMN from the drop down."
		IF app_type = "Select One:" then err_msg = err_msg & vbNewLine & "* Please enter the type of application received."
		IF no_transfer_check = UNCHECKED AND transfer_case_number = "" then err_msg = err_msg & vbNewLine & "* You must enter the basket number the case to be transfered by the script or check that no transfer is needed."
		IF no_transfer_check = CHECKED and transfer_case_number <> "" then err_msg = err_msg & vbNewLine & "* You have checked that no transfer is needed, please remove basket number from transfer field."
    	IF app_type = "ApplyMN" AND isnumeric(confirmation_number) = FALSE THEN err_msg = err_msg & vbNewLine & "If an ApplyMN was received, you must enter the confirmation number and time received"
		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
		LOOP UNTIL err_msg = ""
		CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
	LOOP UNTIL are_we_passworded_out = FALSE					'loops until user passwords back in

HC_applied_for = FALSE
IF app_type = "6696" or app_type = "HCAPP" or app_type = "HC-Certain Pop" or app_type = "LTC" or app_type = "MHCP B/C Cancer"  THEN HC_applied_for = TRUE

IF how_app_rcvd = "Office" and HC_applied_for = FALSE THEN
	same_day_confirmation = MsgBox("This client applied in the office. Will or has the client completed a sameday interview?" & vbNewLine & vbNewLine & "Press YES to confirm a same-day interview was completed." & vbNewLine & "If client declined an interview or one was not offered, press NO." & vbNewLine & vbNewLine & _
	"Application was received in " & how_app_rcvd, vbYesNoCancel, "Application received - same-day interview completed?")
	IF same_day_confirmation = vbNo THEN interview_completed = FALSE
	IF same_day_confirmation = vbYes THEN interview_completed = TRUE
	IF same_day_confirmation = vbCancel THEN script_end_procedure ("The script has ended.")
END IF

If interview_completed = TRUE Then

    Call back_to_SELF
    Call Navigate_to_MAXIS_screen("STAT", "PROG")
    PF9

    intv_day = right("00" & DatePart("d", date), 2)
    Intv_mo  = right("00" & DatePart("m", date), 2)
    intv_yr  = right(DatePart("yyyy", date), 2)

    If cash_pends = TRUE Then
        EmReadscreen interview_date, 8, 6, 55
        If interview_date = "__ __ __" Then
            EmWriteScreen intv_mo, 6, 55
            EmWriteScreen intv_day, 6, 58
            EmWriteScreen intv_yr, 6, 61
        End If
    End If
    If cash2_pends = TRUE Then
        EmReadscreen interview_date, 8, 7, 55
        If interview_date = "__ __ __" Then
            EmWriteScreen intv_mo, 7, 55
            EmWriteScreen intv_day, 7, 58
            EmWriteScreen intv_yr, 7, 61
        End If
    End If
    If SNAP_pends = TRUE Then
        EmReadscreen interview_date, 8, 10, 55
        If interview_date = "__ __ __" Then
            EmWriteScreen intv_mo, 10, 55
            EmWriteScreen intv_day, 10, 58
            EmWriteScreen intv_yr, 10, 61
        End If
    End If

    transmit

    Call back_to_SELF
End If

pended_date = date
'--------------------------------------------------------------------------------initial case note
start_a_blank_case_note
IF case_correction = CHECKED Then
	CALL write_variable_in_CASE_NOTE("~ Case Correction Received (" & app_type & ") via " & how_app_rcvd & " on " & application_date & " ~")
	CALL write_bullet_and_variable_in_CASE_NOTE ("Requested By ", requested_person)
ELSE
	CALL write_variable_in_CASE_NOTE ("~ Application Received (" & app_type & ") via " & how_app_rcvd & " on " & application_date & " ~")
END IF
IF confirmation_number <> "" THEN CALL write_bullet_and_variable_in_CASE_NOTE ("Confirmation # ", confirmation_number)
IF app_type = "6696" THEN write_variable_in_CASE_NOTE ("* Form Rcvd: MNsure Application for Health Coverage and Help Paying Costs (DHS-6696) ")
IF app_type = "HCAPP" THEN write_variable_in_CASE_NOTE ("* Form Rcvd: Health Care Application (HCAPP) (DHS-3417) ")
IF app_type = "HC-Certain Pop" THEN write_variable_in_CASE_NOTE ("* Form Rcvd: MHC Programs Application for Certain Populations (DHS-3876) ")
IF app_type = "LTC" THEN write_variable_in_CASE_NOTE ("* Form Rcvd: Application for Medical Assistance for Long Term Care Services (DHS-3531) ")
IF app_type = "MHCP B/C Cancer" THEN write_variable_in_CASE_NOTE ("* Form Rcvd: Minnesota Health Care Programs Application and Renewal Form Medical Assistance for Women with Breast or Cervical Cancer (DHS-3525) ")
CALL write_bullet_and_variable_in_CASE_NOTE ("Application Requesting", programs_applied_for)
CALL write_bullet_and_variable_in_CASE_NOTE ("Pended on", pended_date)
CALL write_bullet_and_variable_in_CASE_NOTE ("Other Pending Programs", additional_programs_applied_for)
CALL write_bullet_and_variable_in_CASE_NOTE ("Active Programs", active_programs)
If transfer_case_number <> "" THEN CALL write_bullet_and_variable_in_CASE_NOTE ("Application assigned to", transfer_case_number)
CALL write_bullet_and_variable_in_CASE_NOTE ("Other Notes", other_notes)
IF mnsure_retro_checkbox = CHECKED THEN CALL write_variable_in_CASE_NOTE("* Emailed " & requested_person & " to let them know the retro request is ready to be processed.")
If interview_completed = TRUE Then
    CALL write_variable_in_CASE_NOTE ("---")
    CALL write_variable_in_CASE_NOTE("* This case had an interview completed sameday. Interview Date on PROG was checked and updated if needed.")
End If
CALL write_variable_in_CASE_NOTE ("---")
CALL write_variable_in_CASE_NOTE (worker_signature)
PF3 ' to save Case note

'----------------------------------------------------------------------------------------------------EXPEDITED SCREENING!
IF snap_pends = TRUE THEN
    	BeginDialog exp_screening_dialog, 0, 0, 181, 165, "Expedited Screening"
      	EditBox 100, 5, 50, 15, MAXIS_case_number
      	EditBox 100, 25, 50, 15, income
      	EditBox 100, 45, 50, 15, assets
      	EditBox 100, 65, 50, 15, rent
      	CheckBox 15, 95, 55, 10, "Heat (or AC)", heat_AC_check
      	CheckBox 75, 95, 45, 10, "Electricity", electric_check
      	CheckBox 130, 95, 35, 10, "Phone", phone_check
      	ButtonGroup ButtonPressed
        	OkButton 70, 115, 50, 15
        	CancelButton 125, 115, 50, 15
      	Text 10, 140, 160, 15, "The income, assets and shelter costs fields will default to $0 if left blank. "
      	Text 5, 30, 95, 10, "Income received this month:"
      	Text 5, 50, 95, 10, "Cash, checking, or savings: "
      	Text 5, 70, 90, 10, "AMT paid for rent/mortgage:"
      	GroupBox 5, 85, 170, 25, "Utilities claimed (check below):"
      	Text 50, 10, 50, 10, "Case number: "
      	GroupBox 0, 130, 175, 30, "**IMPORTANT**"
    	EndDialog

        'DATE BASED LOGIC FOR UTILITY AMOUNTS------------------------------------------------------------------------------------------
        If application_date >= cdate("10/01/2018") then			'these variables need to change every October
            heat_AC_amt = 493
            electric_amt = 126
            phone_amt = 47
        else
            heat_AC_amt = 556
            electric_amt = 172
            phone_amt = 41
        End if

    	'----------------------------------------------------------------------------------------------------THE SCRIPT
    	CALL MAXIS_case_number_finder(MAXIS_case_number)
    	Do
        	Do
    			err_msg = ""
        		Dialog exp_screening_dialog
        		cancel_confirmation
        		If isnumeric(MAXIS_case_number) = False THEN err_msg = err_msg & vbnewline & "* You must enter a valid case number."
    			If (income <> "" and isnumeric(income) = false) or (assets <> "" and isnumeric(assets) = false) or (rent <> "" and isnumeric(rent) = false) THEN err_msg = err_msg & vbnewline & "* The income/assets/rent fields must be numeric only. Do not put letters or symbols in these sections."
    			If err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine
        	LOOP UNTIL err_msg = ""
    		CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
    	Loop until are_we_passworded_out = false					'loops until user passwords back in

    	''----------------------------------------------------------------------------------------------------LOGIC AND CALCULATIONS
    	'Logic for figuring out utils. The highest priority for the if...THEN is heat/AC, followed by electric and phone, followed by phone and electric separately.
    IF heat_AC_check = CHECKED THEN
       	utilities = heat_AC_amt
    ELSEIF electric_check = CHECKED and phone_check = CHECKED THEN
       	utilities = phone_amt + electric_amt					'Phone standard plus electric standard.
    ELSEIF phone_check = CHECKED and electric_check = UNCHECKED THEN
       	utilities = phone_amt
    ELSEIF electric_check = CHECKED and phone_check = UNCHECKED THEN
       	utilities = electric_amt
    END IF

    'in case no options are clicked, utilities are set to zero.
    IF phone_check = unchecked and electric_check = unchecked and heat_AC_check = unchecked THEN utilities = 0
    'If nothing is written for income/assets/rent info, we set to zero.
    IF income = "" THEN income = 0
    IF assets = "" THEN assets = 0
    IF rent   = "" THEN rent   = 0
    'Calculates expedited status based on above numbers
    IF (int(income) < 150 and int(assets) <= 100) or ((int(income) + int(assets)) < (int(rent) + cint(utilities))) THEN expedited_status = "Client Appears Expedited"
    IF (int(income) + int(assets) >= int(rent) + cint(utilities)) and (int(income) >= 150 or int(assets) > 100) THEN expedited_status = "Client Does Not Appear Expedited"
    '----------------------------------------------------------------------------------------------------checking DISQ
    CALL navigate_to_MAXIS_screen("STAT", "DISQ")
    'grabbing footer month and year
    CALL MAXIS_footer_finder(MAXIS_footer_month, MAXIS_footer_year)
    'Reads the DISQ info for the case note.
    EMReadScreen DISQ_member_check, 34, 24, 2
    IF DISQ_member_check = "DISQ DOES NOT EXIST FOR ANY MEMBER" THEN
      	has_DISQ = False
    ELSE
      	has_DISQ = True
    END IF

    'Reads MONY/DISB to see if EBT account is open
    IF expedited_status = "Client Appears Expedited" THEN
  		CALL navigate_to_MAXIS_screen("MONY", "DISB")
  		EMReadScreen EBT_account_status, 1, 14, 27
        same_day_offered = FALSE

        If interview_completed = TRUE Then same_day_offered = TRUE
        If interview_completed = FALSE Then
            offer_same_date_interview = MsgBox("This client appears EXPEDITED. A same-day needs to be offered." & vbNewLine & vbNewLine & "Has the client been offered a Same Day Interview?", vbYesNo + vbQuestion, "SameDay Offered?")

            if offer_same_date_interview = vbYes Then same_day_offered = TRUE
        End If
  		'MsgBox "This Client Appears EXPEDITED. A same-day interview needs to be offered."
		'same_day_interview = TRUE
		Send_email = TRUE
    END IF

	IF expedited_status = "Client does not appear expedited" THEN MsgBox "This client does NOT appear expedited. A same-day interview does not need to be offered."

    '-----------------------------------------------------------------------------------------------EXPCASENOTE
    start_a_blank_CASE_NOTE
    CALL write_variable_in_CASE_NOTE("~ Received Application for SNAP, " & expedited_status & " ~")
    CALL write_variable_in_CASE_NOTE("---")
    CALL write_variable_in_CASE_NOTE("     CAF 1 income claimed this month: $" & income)
    CALL write_variable_in_CASE_NOTE("         CAF 1 liquid assets claimed: $" & assets)
    CALL write_variable_in_CASE_NOTE("         CAF 1 rent/mortgage claimed: $" & rent)
    CALL write_variable_in_CASE_NOTE("        Utilities (AMT/HEST claimed): $" & utilities)
    CALL write_variable_in_CASE_NOTE("---")
    IF has_DISQ = TRUE THEN CALL write_variable_in_CASE_NOTE("A DISQ panel exists for someone on this case.")
    IF has_DISQ = FALSE THEN CALL write_variable_in_CASE_NOTE("No DISQ panels were found for this case.")
    IF expedited_status = "Client appears expedited" AND EBT_account_status = "Y" THEN CALL write_variable_in_CASE_NOTE("* EBT Account IS open.  Recipient will NOT be able to get a replacement card in the agency.  Rapid Electronic Issuance (REI) with caution.")
    IF expedited_status = "Client appears expedited" AND EBT_account_status = "N" THEN CALL write_variable_in_CASE_NOTE("* EBT Account is NOT open.  Recipient is able to get initial card in the agency.  Rapid Electronic Issuance (REI) can be used, but only to avoid an emergency issuance or to meet EXP criteria.")
    CALL write_variable_in_CASE_NOTE("---")
    IF expedited_status = "Client does not appear expedited" THEN CALL write_variable_in_CASE_NOTE("Client does not appear expedited. Application sent to ECF.")
    IF expedited_status = "Client appears expedited" THEN CALL write_variable_in_CASE_NOTE("Client appears expedited. Application sent to ECF. Emailed Triagers.")
	CALL write_variable_in_CASE_NOTE("---")
	CALL write_variable_in_CASE_NOTE(worker_signature)
END IF

'IF expedited_status = "Client appears expedited" THEN same_day_interview = TRUE
'-------------------------------------------------------------------------------------Transfers the case to the assigned worker if this was selected in the second dialog box
'Determining if a case will be transferred or not. All cases will be transferred except addendum app types. THIS IS NOT CORRECT AND NEEDS TO BE DISCUSSED WITH QI
IF transfer_case_number = "" and no_transfer_check = CHECKED THEN
	transfer_case = False
    action_completed = TRUE     'This is to decide if the case was successfully transferred or not
ELSE
	transfer_case = True
	CALL navigate_to_MAXIS_screen ("SPEC", "XFER")
	EMWriteScreen "x", 7, 16
	transmit
	PF9
	EMWriteScreen "X127" & transfer_case_number, 18, 61
	transmit
	EMReadScreen worker_check, 9, 24, 2

	IF worker_check = "SERVICING" THEN
        action_completed = False
		PF10
	END IF

    EMReadScreen transfer_confirmation, 16, 24, 2
    IF transfer_confirmation = "CASE XFER'D FROM" then
    	action_completed = True
    Else
        action_completed = False
    End if
END IF

'Function create_outlook_email(email_recip, email_recip_CC, email_subject, email_body, email_attachment, send_email)
If run_locally = TRUE Then send_email = FALSE
IF send_email = True THEN CALL create_outlook_email("HSPH.EWS.Triagers@hennepin.us", "", MAXIS_case_name & maxis_case_number & " Expedited case to be assigned, transferred to team. " & worker_number & "  EOM.", "", "", TRUE)
IF mnsure_retro_checkbox = CHECKED THEN CALL create_outlook_email("", "", MAXIS_case_name & maxis_case_number & " Retro Request for MNSURE ready to be processed. " & worker_number & "  EOM.", "", "", FALSE)
'----------------------------------------------------------------------------------------------------NOTICE APPT LETTER Dialog
IF cash_pends = TRUE or cash2_pends = TRUE or SNAP_pends = TRUE or instr(programs_applied_for, "EGA") THEN send_appt_ltr = TRUE
if interview_completed = TRUE Then send_appt_ltr = FALSE
IF send_appt_ltr = TRUE THEN
	BeginDialog Hennepin_appt_dialog, 0, 0, 266, 80, "APPOINTMENT LETTER"
    EditBox 185, 20, 55, 15, interview_date
    ButtonGroup ButtonPressed
    	OkButton 155, 60, 50, 15
    	CancelButton 210, 60, 50, 15
    EditBox 50, 20, 55, 15, application_date
    Text 120, 25, 60, 10, "Appointment date:"
    GroupBox 5, 5, 255, 35, "Enter a new appointment date only if it's a date county offices are not open."
    Text 15, 25, 35, 10, "CAF date:"
    Text 25, 45, 205, 10, "If same-day interview is being offered please use today's date"
  EndDialog

    IF expedited_status = "Client Appears Expedited" THEN
        'creates interview date for 7 calendar days from the CAF date
    	interview_date = dateadd("d", 7, application_date)
    	If interview_date <= date then interview_date = dateadd("d", 7, date)
    ELSE
        'creates interview date for 7 calendar days from the CAF date
    	interview_date = dateadd("d", 10, application_date)
    	If interview_date <= date then interview_date = dateadd("d", 10, date)
    END IF

    Call change_date_to_soonest_working_day(interview_date)

    application_date = application_date & ""
    interview_date = interview_date & ""		'turns interview date into string for variable
 	'need to handle for if we dont need an appt letter, which would be...'

	Do
		Do
    		err_msg = ""
    		dialog Hennepin_appt_dialog
    		cancel_confirmation
			If isdate(application_date) = False then err_msg = err_msg & vbnewline & "* Enter a valid application date."
    		If isdate(interview_date) = False then err_msg = err_msg & vbnewline & "* Enter a valid interview date."
    		IF err_msg <> "" THEN MsgBox "*** NOTICE!!! ***" & vbNewLine & err_msg & vbNewLine		'error message including instruction on what needs to be fixed from each mandatory field if incorrect
    	Loop until err_msg = ""
    	call check_for_password(are_we_passworded_out)  'Adding functionality for MAXIS v.6 Passworded Out issue'
    LOOP UNTIL are_we_passworded_out = false

    'This checks to make sure the case is not in background and is in the correct footer month for PND1 cases.
    Do
    	call navigate_to_MAXIS_screen("STAT", "SUMM")
    	EMReadScreen month_check, 11, 24, 56 'checking for the error message when PND1 cases are not in APPL month
    	IF left(month_check, 5) = "CASES" THEN 'this means the case can't get into stat in current month
    		EMWriteScreen mid(month_check, 7, 2), 20, 43 'writing the correct footer month (taken from the error message)
    		EMWriteScreen mid(month_check, 10, 2), 20, 46 'writing footer year
    		EMWriteScreen "STAT", 16, 43
    		EMWriteScreen "SUMM", 21, 70
    		transmit 'This transmit should take us to STAT / SUMM now
    	END IF
    	'This section makes sure the case isn't locked by background, if it is it will loop and try again
    	EMReadScreen SELF_check, 4, 2, 50
    	If SELF_check = "SELF" then
    		PF3
    		Pause 2
    	End if
    Loop until SELF_check <> "SELF"
	'Navigating to SPEC/MEMO
	Call start_a_new_spec_memo		'Writes the appt letter into the MEMO.
    Call write_variable_in_SPEC_MEMO("You applied for assistance in Hennepin County on " & application_date & "")
    Call write_variable_in_SPEC_MEMO("and an interview is required to process your application.")
    Call write_variable_in_SPEC_MEMO(" ")
    Call write_variable_in_SPEC_MEMO("** The interview must be completed by " & interview_date & ". **")
    Call write_variable_in_SPEC_MEMO("To complete a phone interview, call the EZ Info Line at")
    Call write_variable_in_SPEC_MEMO("612-596-1300 between 9:00am and 4:00pm Monday thru Friday.")
    Call write_variable_in_SPEC_MEMO(" ")
    Call write_variable_in_SPEC_MEMO("* You may be able to have SNAP benefits issued within 24 hours of the interview.")
    Call write_variable_in_SPEC_MEMO(" ")
    Call write_variable_in_SPEC_MEMO("If you wish to schedule an interview, call 612-596-1300. You may also come to any of the six offices below for an in-person interview between 8 and 4:30, Monday thru Friday.")
    Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
    Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
    Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 Th hrs: 8:30-6:30 ")
    Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
    Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
    Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
    Call write_variable_in_SPEC_MEMO("(Hours are M - F 8-4:30 unless otherwise noted)")
    Call write_variable_in_SPEC_MEMO(" ")
    Call write_variable_in_SPEC_MEMO("  ** If we do not hear from you by " & last_contact_day & " **")
    Call write_variable_in_SPEC_MEMO("  **    your application will be denied.     **")
    Call write_variable_in_SPEC_MEMO("If you are applying for a cash program for pregnant women or minor children, you may need a face-to-face interview.")
    Call write_variable_in_SPEC_MEMO(" ")
    Call write_variable_in_SPEC_MEMO("Domestic violence brochures are available at https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
    Call write_variable_in_SPEC_MEMO("You can also request a paper copy.  Auth: 7CFR 273.2(e)(3).")
	PF4

    start_a_blank_CASE_NOTE
	Call write_variable_in_CASE_NOTE("~ Appointment letter sent in MEMO for " & interview_date & " ~")
    Call write_variable_in_CASE_NOTE("* A notice has been sent via SPEC/MEMO informing the client of needed interview.")
    Call write_variable_in_CASE_NOTE("* Households failing to complete the interview within 30 days of the date they file an application will receive a denial notice")
    Call write_variable_in_CASE_NOTE("* A link to the Domestic Violence Brochure sent to client in SPEC/MEMO as part of notice.")
    Call write_variable_in_CASE_NOTE("---")
    CALL write_variable_in_CASE_NOTE (worker_signature)
END IF

IF same_day_offered = TRUE and how_app_rcvd = "Office" THEN
   	start_a_blank_CASE_NOTE
   	Call write_variable_in_CASE_NOTE("~ same-day interview offered ~")
  	Call write_variable_in_CASE_NOTE("* Agency informed the client of needed interview.")
  	Call write_variable_in_CASE_NOTE("* Households failing to complete the interview within 30 days of the date they file an application will receive a denial notice")
  	Call write_variable_in_CASE_NOTE("* A Domestic Violence Brochure has been offered to client as part of application packet.")
  	Call write_variable_in_CASE_NOTE("---")
  	CALL write_variable_in_CASE_NOTE (worker_signature)
	PF3
END IF

IF action_completed = False then
    script_end_procedure ("Warning! Case did not transfer. Transfer the case manually. Script was able to complete all other steps.")
Else
    script_end_procedure ("Case has been updated please review to ensure it was processed correctly.")
End if
