'STATS GATHERING----------------------------------------------------------------------------------------------------
name_of_script = "BULK - APPLICATIONS.vbs"
start_time = timer
STATS_counter = 1                          'sets the stats counter at one
STATS_manualtime = 335                      'manual run time in seconds
STATS_denomination = "C"       			   'C is for each CASE
'END OF stats block==============================================================================================
'TODO Add VGO things

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
		FuncLib_URL = "C:\BZS-FuncLib\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================

' 'Reading Locally held FuncLib in leiu of issues with connecting to GitHub
' Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
' Set fso_command = run_another_script_fso.OpenTextFile("C:\MAXIS-scripts\MASTER FUNCTIONS LIBRARY.vbs")
' text_from_the_other_script = fso_command.ReadAll
' fso_command.Close
' Execute text_from_the_other_script

'CHANGELOG BLOCK ===========================================================================================================
'Starts by defining a changelog array
changelog = array()

'INSERT ACTUAL CHANGES HERE, WITH PARAMETERS DATE, DESCRIPTION, AND SCRIPTWRITER. **ENSURE THE MOST RECENT CHANGE GOES ON TOP!!**
'Example: call changelog_update("01/01/2000", "The script has been updated to fix a typo on the initial dialog.", "Jane Public, Oak County")
CALL changelog_update("07/20/2018", "Updated verbiage of Appointment Notice and NOMI, changed appointment date to 10 days from application date.", "Casey Love, Hennepin County")
CALL changelog_update("07/11/2018", "Adding check to ensure script is not being run in Inquiry.", "Casey Love, Hennepin County")
CALL changelog_update("02/05/2018", "Initial version.", "MiKayla Handley, Hennepin County")


'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'----------------------------------------------------------------------------------------------------Custom function
function start_a_new_spec_memo_and_continue(success_var)
'--- This function navigates user to SPEC/MEMO and starts a new SPEC/MEMO, selecting client, AREP, and SWKR if appropriate
'===== Keywords: MAXIS, notice, navigate, edit
  success_var = True
	call navigate_to_MAXIS_screen("SPEC", "MEMO")				'Navigating to SPEC/MEMO

	PF5															'Creates a new MEMO. If it's unable the script will stop.
	EMReadScreen memo_display_check, 12, 2, 33
	If memo_display_check = "Memo Display" then success_var = False

	'Checking for an AREP. If there's an AREP it'll navigate to STAT/AREP, check to see if the forms go to the AREP. If they do, it'll write X's in those fields below.
	row = 4                             'Defining row and col for the search feature.
	col = 1
	EMSearch "ALTREP", row, col         'Row and col are variables which change from their above declarations if "ALTREP" string is found.
	IF row > 4 THEN                     'If it isn't 4, that means it was found.
	    arep_row = row                                          'Logs the row it found the ALTREP string as arep_row
	    call navigate_to_MAXIS_screen("STAT", "AREP")           'Navigates to STAT/AREP to check and see if forms go to the AREP
	    EMReadscreen forms_to_arep, 1, 10, 45                   'Reads for the "Forms to AREP?" Y/N response on the panel.
	    call navigate_to_MAXIS_screen("SPEC", "MEMO")           'Navigates back to SPEC/MEMO
	    PF5                                                     'PF5s again to initiate the new memo process
	END IF
	'Checking for SWKR
	row = 4                             'Defining row and col for the search feature.
	col = 1
	EMSearch "SOCWKR", row, col         'Row and col are variables which change from their above declarations if "SOCWKR" string is found.
	IF row > 4 THEN                     'If it isn't 4, that means it was found.
	    swkr_row = row                                          'Logs the row it found the SOCWKR string as swkr_row
	    call navigate_to_MAXIS_screen("STAT", "SWKR")         'Navigates to STAT/SWKR to check and see if forms go to the SWKR
	    EMReadscreen forms_to_swkr, 1, 15, 63                'Reads for the "Forms to SWKR?" Y/N response on the panel.
	    call navigate_to_MAXIS_screen("SPEC", "MEMO")         'Navigates back to SPEC/MEMO
	    PF5                                           'PF5s again to initiate the new memo process
	END IF
	EMWriteScreen "x", 5, 12                                        'Initiates new memo to client
	IF forms_to_arep = "Y" THEN EMWriteScreen "x", arep_row, 12     'If forms_to_arep was "Y" (see above) it puts an X on the row ALTREP was found.
	IF forms_to_swkr = "Y" THEN EMWriteScreen "x", swkr_row, 12     'If forms_to_arep was "Y" (see above) it puts an X on the row ALTREP was found.
	transmit                                                        'Transmits to start the memo writing process
end function

' function ONLY_create_MAXIS_friendly_date(date_variable)
' '--- This function creates a MM DD YY date.
' '~~~~~ date_variable: the name of the variable to output
' 	var_month = datepart("m", date_variable)
' 	If len(var_month) = 1 then var_month = "0" & var_month
' 	var_day = datepart("d", date_variable)
' 	If len(var_day) = 1 then var_day = "0" & var_day
' 	var_year = datepart("yyyy", date_variable)
' 	var_year = right(var_year, 2)
' 	date_variable = var_month &"/" & var_day & "/" & var_year
' end function


'LEAVING THIS HERE - NOT USED AT THIS TIME
'However the script has a planned enhancement to update PND2 and checking it will be a good idea.
Function check_pnd2_for_denial(coded_denial, SNAP_pnd2_code, cash_pnd2_code, emer_pnd2_code)
  Call navigate_to_MAXIS_screen("REPT", "PND2")
  row = 7
  col = 5
  EMSearch MAXIS_case_number, row, col      'finding correct case to check PND2 codes

  IF SNAP_check = checked Then
  	EMReadScreen SNAP_pnd2_code, 1, row, 62
  	IF SNAP_pnd2_code = "R" THEN coded_denial = coded_denial & " SNAP withdrawn on PND2."
  	IF SNAP_pnd2_code = "I" THEN coded_denial = coded_denial & " SNAP application incomplete, denied on PND2."
  	IF SNAP_pnd2_code = "_" THEN
  		'If SNAP is selected by the user but the SNAP column is empty on PND2, the script is going to look on the next row for ADDITIONAL APP...
  		EMReadScreen additional_maxis_application, 20, row + 1, 16
  		additional_maxis_application = trim(additional_maxis_application)
  		IF InStr(additional_maxis_application, "ADDITIONAL") <> 0 THEN
  			EMReadScreen SNAP_pnd2_code, 1, row + 1, 62
  			IF SNAP_pnd2_code = "R" THEN coded_denial = coded_denial & " SNAP withdrawn on PND2."
  			IF SNAP_pnd2_code = "I" THEN coded_denial = coded_denial & " SNAP application incomplete, denied on PND2."
  		END IF
  	END IF
  END IF
  IF cash_check = checked Then
  	EMReadScreen cash_pnd2_code, 1, row, 54
  	IF cash_pnd2_code = "R" THEN coded_denial = coded_denial & " CASH withdrawn on PND2."
  	IF cash_pnd2_code = "I" THEN coded_denial = coded_denial & " CASH application incomplete, denied on PND2."
  	IF cash_pnd2_code = "_" THEN
  		'If CASH is selected by the user but the CASH column is empty on PND2, the script is going to look on the next row for ADDITIONAL APP...
  		EMReadScreen additional_maxis_application, 20, row + 1, 16
  		additional_maxis_application = trim(additional_maxis_application)
  		IF InStr(additional_maxis_application, "ADDITIONAL") <> 0 THEN
  			EMReadScreen cash_pnd2_code, 1, row + 1, 54
  			IF cash_pnd2_code = "R" THEN coded_denial = coded_denial & " CASH withdrawn on PND2."
  			IF cash_pnd2_code = "I" THEN coded_denial = coded_denial & " CASH application incomplete, denied on PND2."
  		END IF
  	END IF
  END IF
End function


function convert_to_mainframe_date(date_var, yr_len)
    'This will change a variable to mm/dd/yy or mm/dd/yyyy format for comparison to dates in MX
    'yr_len should be a number - either 2 or 4
    'MsgBox date_var
    month_to_use = DatePart("m", date_var)
    month_to_use = right("00" & month_to_use, 2)

    day_to_use = DatePart("d", date_var)
    day_to_use = right("00" & day_to_use, 2)

    year_to_use = DatePart("yyyy", date_var)
    year_to_use = right(year_to_use, yr_len)

    date_var = month_to_use & "/" & day_to_use & "/" & year_to_use
end function

function confirm_memo_waiting(confirmation_var)
    'Function to read for a MEMO created and waiting today
    'This is used to confirm that MEMO creation was successful
    memo_row = 7

    today_date = date
    Call convert_to_mainframe_date(today_date, 2)

    Do
        EMReadScreen create_date, 8, memo_row, 19                 'Reading the date of each memo and the status
        EMReadScreen print_status, 7, memo_row, 67
        'MsgBox print_status
        If create_date = today_date AND print_status = "Waiting" Then   'MEMOs created today and still waiting is likely our MEMO.
            confirmation_var = "Y"             'If we've found this then no reason to keep looking.
            successful_notices = successful_notices + 1
            'MsgBox ALL_PENDING_CASES_ARRAY(notc_confirm, case_entry)                 'For statistical purposes
            Exit Do
        End If
        memo_row = memo_row + 1           'Looking at next row'
    Loop Until create_date = "        "
end function

function go_to_top_of_notes()
    'Function to move to the top of the CASE/NOTE screen because it might have to look for different things
    Do
        PF7
        EMReadScreen top_of_notes_check, 10, 24, 14
    Loop until top_of_notes_check = "FIRST PAGE"
end function

function convert_date_to_day_first(date_to_convert, date_to_output)
    intv_date_mo = DatePart("m", date_to_convert)
    intv_date_day = DatePart("d", date_to_convert)
    intv_date_yr = DatePart("yyyy", date_to_convert)
    date_to_output = intv_date_day & "/" & intv_date_mo & "/" & intv_date_yr
end function

'THE SCRIPT-------------------------------------------------------------------------------------------------------------------------
EMConnect ""		'Connects to BlueZone
'Grabbing the worker's X number.
CALL find_variable("User: ", worker_number, 7)

'Starting the query start time (for the query runtime at the end)
query_start_time = timer

'if user is not Hennepin County - the script will end. Process is not approved for other counties
'------------------------------------------------------------------------------------------------------establishing date variables
MAXIS_footer_month = CM_plus_1_mo   'Setting footer month and year
MAXIS_footer_year = CM_plus_1_yr

' CM_minus_1_mo = right("0" & DatePart("m", DateAdd("m", -1, date)), 2)
' CM_minus_1_yr = right(DatePart("yyyy", DateAdd("m", -1, date)), 2)

'current_date = date
'Call ONLY_create_MAXIS_friendly_date(current_date)			'reformatting the dates to be MM/DD/YY format to measure against the panel dates

'Opens the current day's list
'dialog and dialog DO...Loop
Do
	Do
		'The dialog is defined in the loop as it can change as buttons are pressed
        BeginDialog file_select_dialog, 0, 0, 316, 175, "Select the source file"
          EditBox 5, 125, 260, 15, file_selection_path
          ButtonGroup ButtonPressed
            PushButton 270, 125, 40, 15, "Browse...", select_a_file_button
            OkButton 205, 155, 50, 15
            CancelButton 260, 155, 50, 15
          Text 5, 5, 305, 25, "This script will send Appointment Notices and NOMIs or update for denials when no interview has been completed. Once an interview has taken place, this script no longer takes action on the case."
          Text 5, 35, 255, 10, "Cases with an interview completed should have the interview listed on PROG."
          Text 5, 50, 310, 10, "An Appointment Notice will be sent on any case without a case note of appointment notice sent."
          Text 5, 65, 300, 10, "A NOMI will be sent once the appointment date indicated on Appointment Notice has passed."
          Text 5, 80, 305, 20, "A denial will be indicated when a case reaches day 30 (unless the NOMI did not go out until day 30 or after)."
          Text 10, 105, 295, 15, "Click the BROWSE button and select the BOBI report for today. Once selected, click 'OK'. There will be no additional input needed until the script run is complete."
          Text 5, 150, 160, 20, "Reminder, do not use Excel during the time the script is running. The script needs to use Excel."
        EndDialog

		err_msg = ""
		Dialog file_select_dialog
		If ButtonPressed = cancel then stopscript
		If ButtonPressed = select_a_file_button then
			If file_selection_path <> "" then 'This is handling for if the BROWSE button is pushed more than once'
				objExcel.Quit 'Closing the Excel file that was opened on the first push'
				objExcel = "" 	'Blanks out the previous file path'
			End If
			call file_selection_system_dialog(file_selection_path, ".xlsx") 'allows the user to select the file'
            If file_selection_path = "" then
                err_msg = err_msg & vbNewLine & "Use the Browse Button to select the file that has your client data"
            Else
                If objExcel <> "" Then          'If there is already an excel sheet open and the browse button is pressed again - the first excel is closed and blanked out so a new one can be entered.
                    objExcel.quit
                    objExcel = ""
                End If
                call excel_open(file_selection_path, True, True, ObjExcel, objWorkbook)  'opens the selected excel file'
                err_msg = err_m & vbNewLine & "Be sure the correct Excel file opened."
            End If
		End If

		If err_msg <> "" Then MsgBox err_msg      'Display the error message
	Loop until err_msg = ""
	CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
Loop until are_we_passworded_out = false					'loops until user passwords back in

call back_to_self
EMReadScreen mx_region, 10, 22, 48

If mx_region = "INQUIRY DB" Then
    continue_in_inquiry = MsgBox("It appears you are attempting to have the script send notices for these cases." & vbNewLine & vbNewLine & "However, you appear to be in MAXIS Inquiry." &vbNewLine & "*************************" & vbNewLine & "Do you want to continue?", vbQuestion + vbYesNo, "Confirm Inquiry")
    If continue_in_inquiry = vbNo Then script_end_procedure("Live script run was attempted in Inquiry and aborted.")
End If

'confirming that there is a worker signature on file.
If trim(worker_signature) = "" Then
    worker_signature = InputBox("How would you like to sign you case notes:", "Worker Signature")
End If
'Activates worksheet based on user selection
objExcel.worksheets("Report 1").Activate

'Setting constants to make the arrays easier to read
const case_number           = 0
const excel_row             = 1
const client_name			= 2
const program_group_ID		= 3
const worker_ID		   		= 4
const program_status		= 5
const priv_case             = 6
const out_of_co             = 7
const written_lang          = 8
const SNAP_status           = 9
const CASH_status           = 10
const application_date      = 11
const interview_date    	= 12
const appt_notc_sent        = 13
const appt_notc_confirm     = 14
const nomi_sent             = 15
const nomi_confirm          = 16
const deny_day30			= 17
const deny_memo_confirm     = 18
const need_appt_notc        = 19
const need_nomi             = 20
const appointment_date		= 21
const next_action_needed    = 22
const on_working_list       = 23
const questionable_intv     = 24
const take_action_today     = 25
const need_face_to_face     = 26
const error_notes 			= 27

'Constants for columns in the working excel sheet - to make the excel code easier to read.
const worker_id_col         = 1
const case_nbr_col          = 2
const case_name_col         = 3
const snap_stat_col         = 4
const cash_stat_col         = 5
const app_date_col          = 6
const intvw_date_col        = 7
const quest_intvw_date_col  = 8
const ftof_still_need_col   = 9
const appt_notc_date_col    = 10
const appt_date_col         = 11
const appt_notc_confirm_col = 12
const nomi_date_col         = 13
const nomi_confirm_col      = 14
const need_deny_col         = 15
const deny_notc_confirm_col = 16
const next_action_col       = 17
const day_30_col            = 18
const correct_need_col      = 19
const action_worker_col     = 20
const action_sup_col        = 21
const email_sent_col        = 22

'ARRAY used to store ALL the cases listed on the BOBI today
Dim TODAYS_CASES_ARRAY()
ReDim TODAYS_CASES_ARRAY(error_notes, 0)

'Setting a starting value for a list of cases so that every case is bracketed by * on both sides.
todays_cases_list = "*"
case_entry = 0      'Setting an incrementer for the array to be filled
row = 5             'The BOBI report has cases starting at row 5

'Goes through the list, and creates an array of all cases - removing duplicates and removing cases with an interview date already listed
Do
    anything_number = trim(objExcel.Cells(row, 3).value)            'anything_number is just a placeholder for looking at the case numbers
    'MsgBox anything_number
    If instr(todays_cases_list, "*" & anything_number & "*") = 0 then       'This indicates that the case number was not already found on the BOBI
        'MsgBox anything_number
        todays_cases_list = todays_cases_list & anything_number & "*"       'adding the case number on the current row to the list of all the case numbers found.
        ReDim Preserve TODAYS_CASES_ARRAY(error_notes, case_entry)          'resizing the array to add this case to the array

        'Saving each piece of case information from the BOBI to the array
        TODAYS_CASES_ARRAY(worker_ID, case_entry) = trim(objExcel.Cells(row, 2).value)
        TODAYS_CASES_ARRAY(case_number, case_entry) = trim(objExcel.Cells(row, 3).value)
        TODAYS_CASES_ARRAY(excel_row, case_entry) = row
        TODAYS_CASES_ARRAY(client_name, case_entry) = trim(objExcel.cells(row, 4).value) 'storing all of the excel information
        TODAYS_CASES_ARRAY(application_date, case_entry) = trim(objExcel.cells(row, 7).value)
        TODAYS_CASES_ARRAY(interview_date, case_entry) = trim(objExcel.cells(row, 8).value)
        TODAYS_CASES_ARRAY(on_working_list, case_entry) = FALSE         'defaulting this to FALSE

        current_number = anything_number    'saving the case number that is being looked at for the next loop because these are sorted by case number
        case_entry = case_entry + 1         'incrementing for the array to resize on the next loop
    ElseIf anything_number = current_number Then    'this is if we are looking at the same case still
        'Checking to see if one of the later lines for the case indicates no interview = this will make the array show no interview if EITHER Cash or SNAP have no interview indicated in PROG
        If trim(objExcel.cells(row, 8).value) = "" Then TODAYS_CASES_ARRAY(interview_date, case_entry-1) = ""
    End If
    stats_counter = stats_counter + 1       'incrementing for stats

    row = row + 1   'Going to the next row
    next_case_number = trim(objExcel.Cells(row, 3).Value)
loop until next_case_number = ""

objExcel.quit       'Once the array is created - we no longer need this Excel sheet open, and since we are going to open another one, it is safer to close it.

'Opens the working excel spreadsheet.
'This file path is hard coded because it is always the same file
'working_excel_file_path = "T:\Eligibility Support\Restricted\QI - Quality Improvement\BZ scripts project\Projects\On Demand Waiver\Files for testing new application rewrite\Working Excel.xlsx"
working_excel_file_path = "T:\Eligibility Support\Restricted\QI - Quality Improvement\REPORTS\On Demand Waiver\Working Excel.xlsx"     'THIS IS THE REAL ONE

'Opens Excel file here, as it needs to populate the dialog with the details from the spreadsheet.
call excel_open(working_excel_file_path, True, True, ObjWorkExcel, objWorkbook)

'ARRAY of all the cases that are on the working spreadsheet (this is essentially the spreadsheet doumped into a script array for use)
Dim ALL_PENDING_CASES_ARRAY()
ReDim ALL_PENDING_CASES_ARRAY(error_notes, 0)
'ARRAY of all the cases that are removed from the working spreadsheet so that they can be reported out after the script run
Dim CASES_NO_LONGER_WORKING()
ReDim CASES_NO_LONGER_WORKING(error_notes, 0)

case_entry = 0      'incrementer to add a case to ALL_PENDING_CASES_ARRAY
case_removed = 0    'incrementer to add a case to CASES_NO_LONGER_WORKING
row = 2             'Working Excel sheet starts with cases on row 2

'This do loops through all of the cases that are already on the working sheet to see if we can find them in today's array
Do
    case_number_to_assess = trim(objWorkExcel.Cells(row, 2).Value)  'getting the case number in the Working Excel sheet
    found_case_on_todays_list = FALSE                               'this boolean is used to determine if the case number is on the BOBI run today
    If trim(case_number_to_assess) = "" Then Exit DO                'if the cell is blank, we are at the end of the list.

    For each_case = 0 to UBound(TODAYS_CASES_ARRAY, 2)              'This loops through each case that was on the BOBI today
        'MsgBox "Excel case number: " & case_number_to_assess & vbNewLine & "Array case number: " & TODAYS_CASES_ARRAY(case_number, each_case)
        If case_number_to_assess = TODAYS_CASES_ARRAY(case_number, each_case) Then  'If a matching case number is found this means the case was on the working excel AND is on the BOBI
            TODAYS_CASES_ARRAY(on_working_list, each_case) = TRUE                   'Idetifying in the list of the cases on the BOBI that this case was also on the working list - and so won't need to be added later
            found_case_on_todays_list = TRUE                                        'Identifying that this row on the working list was also found on the BOBI - so it won't necessarily have to be removed from the working list later
            'MsgBox "Excel case number: " & case_number_to_assess & vbNewLine & "Array case number: " & TODAYS_CASES_ARRAY(case_number, each_case)
            If TODAYS_CASES_ARRAY(interview_date, each_case) <> "" Then             'If the BOBI reported indicated that an interview has been completed for all programs for a case on the Working lise
                'Remove from working sheet and add to list of cases removed
                'MsgBox "Interview Date: " & TODAYS_CASES_ARRAY(interview_date, each_case)
                ReDim Preserve CASES_NO_LONGER_WORKING(error_notes, case_removed)       'It is removed from the working list and added to an ARRAY of all the cases removed from the working list that day.
                CASES_NO_LONGER_WORKING(worker_ID, case_removed) = TODAYS_CASES_ARRAY(worker_ID, each_case)
                CASES_NO_LONGER_WORKING(case_number, case_removed) = TODAYS_CASES_ARRAY(case_number, each_case)
                CASES_NO_LONGER_WORKING(excel_row, case_removed) = row
                CASES_NO_LONGER_WORKING(client_name, case_removed) = TODAYS_CASES_ARRAY(client_name, each_case)
                CASES_NO_LONGER_WORKING(application_date, case_removed) = ObjWorkExcel.Cells(row, app_date_col)
                'CASES_NO_LONGER_WORKING(interview_date, case_removed) = ObjWorkExcel.Cells(row, intvw_date_col)
                CASES_NO_LONGER_WORKING(interview_date, case_removed) = TODAYS_CASES_ARRAY(interview_date, each_case)
                CASES_NO_LONGER_WORKING(CASH_status, case_removed) = ObjWorkExcel.Cells(row, cash_stat_col)
                CASES_NO_LONGER_WORKING(SNAP_status, case_removed) = ObjWorkExcel.Cells(row, snap_stat_col)

                CASES_NO_LONGER_WORKING(appt_notc_sent, case_removed) = ObjWorkExcel.Cells(row, appt_notc_date_col)
                CASES_NO_LONGER_WORKING(appt_notc_confirm, case_removed) = ObjWorkExcel.Cells(row, appt_notc_confirm_col).Value
                CASES_NO_LONGER_WORKING(appointment_date, case_removed) = ObjWorkExcel.Cells(row, appt_date_col)
                CASES_NO_LONGER_WORKING(nomi_sent, case_removed) = ObjWorkExcel.Cells(row, nomi_date_col)
                CASES_NO_LONGER_WORKING(nomi_confirm, case_removed) = ObjWorkExcel.Cells(row, nomi_confirm_col)
                CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = ObjWorkExcel.Cells(row, next_action_col)
                CASES_NO_LONGER_WORKING(questionable_intv, case_removed) = ObjWorkExcel.Cells(row, quest_intvw_date_col)
                CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = ObjWorkExcel.Cells(row, ftof_still_need_col)

                CASES_NO_LONGER_WORKING(error_notes, case_removed) = "Interview Completed on " & TODAYS_CASES_ARRAY(interview_date, each_case)  'This field is used on the removed cases list to indicate WHY it no longer needs to be on the working list

                case_removed = case_removed + 1     'increasing the incrementer for the removed cases ARRAY
                'DELETING THE ROW FOR THIS CASE FROM THE WORKING LIST- notice that ROW does not increase as the curent row is now new
                SET objRange = ObjWorkExcel.Cells(row, 1).EntireRow
                objRange.Delete
            ElseIf ObjWorkExcel.Cells(row, next_action_col) = "REMOVE FROM LIST" Then       'These cases were flagged on the Working Excel to be removed - usually because neither CASH or SNAP are pending any more.
                'MsgBox "REMOVE FROM LIST"
                ReDim Preserve CASES_NO_LONGER_WORKING(error_notes, case_removed)           'It is removed from the working list and added to an ARRAY of all the cases removed from the working list that day.
                CASES_NO_LONGER_WORKING(worker_ID, case_removed) = ObjWorkExcel.Cells(row, worker_id_col)
                CASES_NO_LONGER_WORKING(case_number, case_removed) = ObjWorkExcel.Cells(row, case_nbr_col)
                CASES_NO_LONGER_WORKING(excel_row, case_removed) = row
                CASES_NO_LONGER_WORKING(client_name, case_removed) = ObjWorkExcel.Cells(row, case_name_col)
                CASES_NO_LONGER_WORKING(application_date, case_removed) = ObjWorkExcel.Cells(row, app_date_col)
                'CASES_NO_LONGER_WORKING(interview_date, case_removed) = ObjWorkExcel.Cells(row, intvw_date_col)
                CASES_NO_LONGER_WORKING(interview_date, case_removed) = ObjWorkExcel.Cells(row, intvw_date_col)
                CASES_NO_LONGER_WORKING(CASH_status, case_removed) = ObjWorkExcel.Cells(row, cash_stat_col)
                CASES_NO_LONGER_WORKING(SNAP_status, case_removed) = ObjWorkExcel.Cells(row, snap_stat_col)

                CASES_NO_LONGER_WORKING(appt_notc_sent, case_removed) = ObjWorkExcel.Cells(row, appt_notc_date_col)
                CASES_NO_LONGER_WORKING(appt_notc_confirm, case_removed) = ObjWorkExcel.Cells(row, appt_notc_confirm_col).Value
                CASES_NO_LONGER_WORKING(appointment_date, case_removed) = ObjWorkExcel.Cells(row, appt_date_col)
                CASES_NO_LONGER_WORKING(nomi_sent, case_removed) = ObjWorkExcel.Cells(row, nomi_date_col)
                CASES_NO_LONGER_WORKING(nomi_confirm, case_removed) = ObjWorkExcel.Cells(row, nomi_confirm_col)
                CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = ObjWorkExcel.Cells(row, next_action_col)
                CASES_NO_LONGER_WORKING(questionable_intv, case_removed) = ObjWorkExcel.Cells(row, quest_intvw_date_col)
                CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = ObjWorkExcel.Cells(row, ftof_still_need_col)

                CASES_NO_LONGER_WORKING(error_notes, case_removed) = "No programs pending."     'This field is used on the removed list to indicate WHY it is no longer on the Working Excel

                'CASES_NO_LONGER_WORKING(error_notes, case_removed) = "Interview Completed on " & TODAYS_CASES_ARRAY(interview_date, case_entry)
                'MsgBox row
                case_removed = case_removed + 1             'adding to the incrementer for the removed cases ARRAY
                'DELETING THE ROW FOR THIS CASE FROM THE WORKING LIST- notice that ROW does not increase as the curent row is now new
                SET objRange = ObjWorkExcel.Cells(row, 1).EntireRow
                objRange.Delete
            Else        'Any case that does not have an interview completed or was previously inidcated as no longer pending is still potentially in need of a notice or denial - and is already listed on the Working Excel
                ReDim Preserve ALL_PENDING_CASES_ARRAY(error_notes, case_entry)     'resizing the WORKING CASES ARRAY
                'Now basically the Excel sheet is transcriped row by row to the script ARRAY so we can work with it.
                ALL_PENDING_CASES_ARRAY(worker_ID, case_entry) = TODAYS_CASES_ARRAY(worker_ID, each_case)
                ALL_PENDING_CASES_ARRAY(case_number, case_entry) = TODAYS_CASES_ARRAY(case_number, each_case)
                ALL_PENDING_CASES_ARRAY(excel_row, case_entry) = row
                ALL_PENDING_CASES_ARRAY(client_name, case_entry) = ObjWorkExcel.Cells(row, case_name_col)       'This is gathered from the Working Excel instead of the BOBI list because we may have populated a priv case with an actual name
                ALL_PENDING_CASES_ARRAY(application_date, case_entry) = ObjWorkExcel.Cells(row, app_date_col)
                ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = ObjWorkExcel.Cells(row, intvw_date_col)   'This is gathered from the Working Excel as we may have found an interview date that is NOT in PROG
                ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = ObjWorkExcel.Cells(row, cash_stat_col)
                ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) = ObjWorkExcel.Cells(row, snap_stat_col)

                ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = ObjWorkExcel.Cells(row, appt_notc_date_col)
                ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry) = ObjWorkExcel.Cells(row, appt_notc_confirm_col).Value
                ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = ObjWorkExcel.Cells(row, appt_date_col)
                ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = ObjWorkExcel.Cells(row, nomi_date_col)
                ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry) = ObjWorkExcel.Cells(row, nomi_confirm_col)
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = ObjWorkExcel.Cells(row, next_action_col)
                ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ObjWorkExcel.Cells(row, quest_intvw_date_col)
                ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = ObjWorkExcel.Cells(row, ftof_still_need_col)

                'ALL_PENDING_CASES_ARRAY(, case_entry) = ObjWorkExcel.Cells(row, )

                'Defaulting this values at this time as we will determine them to be different as the script proceeds.
                ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = FALSE
                case_entry = case_entry + 1     'increasing the count for '
                row = row + 1                   'moving to the next row
            End If
            Exit For                            'This is to leave the loop of looking through all of the cases in the BOBI list ARRAY because we found the match - and there should never be duplicates
        End If
    Next

    'If the script has looked through ALL the cases on the BOBI list for today and there was no match for the case number of the row of the Working Excel that we are on
    'It means that the case is no longer pending for CASH nor for SNAP and we no longer need to look at it.
    If found_case_on_todays_list = FALSE Then   'this was defaulted to FALSE and is only changed to TRUE when a case number match on today's BOBI list
        'MsgBox "NOT ON TODAY'S LIST" & vbNewLine & ObjWorkExcel.Cells(row, case_nbr_col)
        ReDim Preserve CASES_NO_LONGER_WORKING(error_notes, case_removed)       'increasing the size of the array
        'Gathering all the detail from the working Excel and adding to the removed CASES ARRAY so that we can list it at the end.
        CASES_NO_LONGER_WORKING(worker_ID, case_removed) = ObjWorkExcel.Cells(row, worker_id_col)
        CASES_NO_LONGER_WORKING(case_number, case_removed) = ObjWorkExcel.Cells(row, case_nbr_col)
        CASES_NO_LONGER_WORKING(excel_row, case_removed) = row
        CASES_NO_LONGER_WORKING(client_name, case_removed) = ObjWorkExcel.Cells(row, case_name_col)
        CASES_NO_LONGER_WORKING(application_date, case_removed) = ObjWorkExcel.Cells(row, app_date_col)
        'CASES_NO_LONGER_WORKING(interview_date, case_removed) = ObjWorkExcel.Cells(row, intvw_date_col)
        CASES_NO_LONGER_WORKING(interview_date, case_removed) = ObjWorkExcel.Cells(row, intvw_date_col)
        CASES_NO_LONGER_WORKING(CASH_status, case_removed) = ObjWorkExcel.Cells(row, cash_stat_col)
        CASES_NO_LONGER_WORKING(SNAP_status, case_removed) = ObjWorkExcel.Cells(row, snap_stat_col)

        CASES_NO_LONGER_WORKING(appt_notc_sent, case_removed) = ObjWorkExcel.Cells(row, appt_notc_date_col)
        CASES_NO_LONGER_WORKING(appt_notc_confirm, case_removed) = ObjWorkExcel.Cells(row, appt_notc_confirm_col).Value
        CASES_NO_LONGER_WORKING(appointment_date, case_removed) = ObjWorkExcel.Cells(row, appt_date_col)
        CASES_NO_LONGER_WORKING(nomi_sent, case_removed) = ObjWorkExcel.Cells(row, nomi_date_col)
        CASES_NO_LONGER_WORKING(nomi_confirm, case_removed) = ObjWorkExcel.Cells(row, nomi_confirm_col)
        CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = ObjWorkExcel.Cells(row, next_action_col)
        CASES_NO_LONGER_WORKING(questionable_intv, case_removed) = ObjWorkExcel.Cells(row, quest_intvw_date_col)

        CASES_NO_LONGER_WORKING(error_notes, case_removed) = ""
        'CASES_NO_LONGER_WORKING(error_notes, case_removed) = "Interview Completed on " & TODAYS_CASES_ARRAY(interview_date, case_entry)
        'MsgBox row
        case_removed = case_removed + 1     'adding to the incrementer for the removed cases ARRAY
        'Actually deleting the row in the Working Excel - notice that ROW does not increase as the curent row is now new
        SET objRange = ObjWorkExcel.Cells(row, 1).EntireRow
        objRange.Delete
    End If

    next_case_number = trim(objWorkExcel.Cells(row, 1).Value)       'looking for when to exit the loop - when we reach the end of the Working Excel
Loop Until next_case_number = ""

'BE SURE TO ALWAYS LEAVE THE row VARIABLE ALONE HERE AS WE USE IT IN THIS FOR NEXT TO ADD TO THE END OF THE WORKING EXCEL
add_a_case = case_entry     'creating an incrementer that starts where the last one ended for the ALL PENDING CASES ARRAY
For case_entry = 0 to UBOUND(TODAYS_CASES_ARRAY, 2)     'now we are going to look at each of the cases in the ARRAY for today's BOBI list
    'MsgBox TODAYS_CASES_ARRAY(on_working_list, case_entry)
    'MsgBox TODAYS_CASES_ARRAY(interview_date, case_entry)
    If TODAYS_CASES_ARRAY(on_working_list, case_entry) = FALSE AND TODAYS_CASES_ARRAY(interview_date, case_entry) = "" Then
        'These are all the cases on todays list that were NOT on the Working Excel AND have not already had an interview
        'adding the information known from the BOBI to the Working Excel
        ObjWorkExcel.Cells(row, worker_id_col) = TODAYS_CASES_ARRAY(worker_ID, case_entry)
        ObjWorkExcel.Cells(row, case_nbr_col) = TODAYS_CASES_ARRAY(case_number, case_entry)
        ObjWorkExcel.Cells(row, case_name_col) = TODAYS_CASES_ARRAY(client_name, case_entry)
        ObjWorkExcel.Cells(row, app_date_col) = TODAYS_CASES_ARRAY(application_date, case_entry)
        ObjWorkExcel.Cells(row, intvw_date_col) = TODAYS_CASES_ARRAY(interview_date, case_entry)

        'ObjWorkExcel.Cells(row, ) = TODAYS_CASES_ARRAY(, case_entry)

        ReDim Preserve ALL_PENDING_CASES_ARRAY(error_notes, add_a_case)         'resizing the array of the Working Excel
        'Now all the information needs to be added to the ARRAY from the Working Excel
        ALL_PENDING_CASES_ARRAY(worker_ID, add_a_case) = TODAYS_CASES_ARRAY(worker_ID, case_entry)
        ALL_PENDING_CASES_ARRAY(case_number, add_a_case) = TODAYS_CASES_ARRAY(case_number, case_entry)
        ALL_PENDING_CASES_ARRAY(excel_row, add_a_case) = row
        ALL_PENDING_CASES_ARRAY(client_name, add_a_case) = TODAYS_CASES_ARRAY(client_name, case_entry)
        ALL_PENDING_CASES_ARRAY(application_date, add_a_case) = ObjWorkExcel.Cells(row, app_date_col)
        ALL_PENDING_CASES_ARRAY(interview_date, add_a_case) = ObjWorkExcel.Cells(row, intvw_date_col)
        ALL_PENDING_CASES_ARRAY(CASH_status, add_a_case) = ObjWorkExcel.Cells(row, cash_stat_col)
        ALL_PENDING_CASES_ARRAY(SNAP_status, add_a_case) = ObjWorkExcel.Cells(row, snap_stat_col)

        ALL_PENDING_CASES_ARRAY(appt_notc_sent, add_a_case) = ObjWorkExcel.Cells(row, appt_notc_date_col)
        ALL_PENDING_CASES_ARRAY(appt_notc_confirm, add_a_case) = ObjWorkExcel.Cells(row, appt_notc_confirm_col).Value
        ALL_PENDING_CASES_ARRAY(appointment_date, add_a_case) = ObjWorkExcel.Cells(row, appt_date_col)
        ALL_PENDING_CASES_ARRAY(nomi_sent, add_a_case) = ObjWorkExcel.Cells(row, nomi_date_col)
        ALL_PENDING_CASES_ARRAY(nomi_confirm, add_a_case) = ObjWorkExcel.Cells(row, nomi_confirm_col)
        ALL_PENDING_CASES_ARRAY(next_action_needed, add_a_case) = ObjWorkExcel.Cells(row, next_action_col)
        ALL_PENDING_CASES_ARRAY(questionable_intv, add_a_case) = ObjWorkExcel.Cells(row, quest_intvw_date_col)
        ALL_PENDING_CASES_ARRAY(need_face_to_face, add_a_case) = ObjWorkExcel.Cells(row, ftof_still_need_col)

        'ALL_PENDING_CASES_ARRAY(, add_a_case) = ObjWorkExcel.Cells(row, )

        'defaulting this variable as we will determine if it is true later
        ALL_PENDING_CASES_ARRAY(take_action_today, add_a_case) = FALSE

        add_a_case = add_a_case + 1     'incrementing the counter for this ARRAY
        row = row + 1                   'going to the next row so that we don't overwrite the information we just added
    End If
Next

'Now we are going to start gathering information from MAXIS
'Excel will not be accessed during this loop - we could add msgbox to let worker know that excel is available.
For case_entry = 0 to UBOUND(ALL_PENDING_CASES_ARRAY, 2)
    MAXIS_case_number	= ALL_PENDING_CASES_ARRAY(case_number, case_entry)        'setting this so that nav functionality works
    'MsgBox ALL_PENDING_CASES_ARRAY(case_number, case_entry)
    back_to_SELF
    CALL navigate_to_MAXIS_screen("CASE", "CURR")
    'Checking for PRIV cases.
    EMReadScreen priv_check, 6, 24, 14              'If it can't get into the case needs to skip
    EMReadScreen county_check, 2, 21, 16            'Looking to see if case has Hennepin COunty worker
    EMReadScreen case_removed_in_MAXIS, 19, 24, 2   'There was one case that was removed from MX and it got a little weird.
    If priv_check = "PRIVIL" THEN
        priv_case_list = priv_case_list & "|" & MAXIS_case_number
        ALL_PENDING_CASES_ARRAY(priv_case, case_entry) = TRUE
    ElseIf county_check <> "27" THEN
        ALL_PENDING_CASES_ARRAY(out_of_co, case_entry) = "OUT OF COUNTY - " & county_check
    ElseIf case_removed_in_MAXIS = "INVALID CASE NUMBER" Then
        ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "CASE HAS BEEN DELETED"
    Else
        ALL_PENDING_CASES_ARRAY(priv_case, case_entry) = FALSE

        'These caseloads have IMD cases and it is imporatnt to note them.
        IF ALL_PENDING_CASES_ARRAY(worker_ID, case_entry) = "X127EF8" or ALL_PENDING_CASES_ARRAY(worker_ID, case_entry) = "X127EJ1" THEN ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", IMD CASE"

        'Some PRIV cases do not have the client name in BOBI - this will find them
        If ALL_PENDING_CASES_ARRAY(client_name, case_entry) = "XXXXX" Then
            Call navigate_to_MAXIS_screen("STAT", "MEMB")       'go to MEMB - do not need to chose a different memb number because we are looking for the case name
            EMReadScreen last_name, 25, 6, 30       'read each name
            EMReadScreen first_name, 12, 6, 63
            EMReadScreen middle_initial, 1, 6, 79

            last_name = replace(last_name, "_", "") 'format so there are no underscores
            first_name = replace(first_name, "_", "")
            middle_initial = replace(middle_initial, "_", "")

            ALL_PENDING_CASES_ARRAY(client_name, case_entry) = last_name & ", " & first_name & " " & middle_initial     'this is how the BOBI lists names so we want them to match
        End If

        'PROG to determine programs pending and interview dates
        Call navigate_to_MAXIS_screen("STAT", "PROG")
        fs_intv = ""            'These need to be blanked out for each run as sometimes they are not found for each run and so there is carryover
        cash_intv_one = ""
        cash_intv_two = ""

        'reading programs types and statuses
        EMReadScreen cash_prog_one, 2, 6, 67
        EMReadScreen cash_stat_one, 4, 6, 74

        EMReadScreen cash_prog_two, 2, 7, 67
        EMReadScreen cash_stat_two, 4, 7, 74

        EMReadScreen fs_pend, 4, 10, 74

        'defaulting these to false for each run through the loop
        cash_pend = FALSE
        cash_interview_done = FALSE
        snap_interview_done = FALSE

        ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = ""       'resetting this so that if it has changed we get good information

        If cash_stat_one = "PEND" Then                              'If the first cash line indicates pending - look for interview information
            cash_pend = TRUE                                        'defining cash as a pending program
            EMReadScreen cash_intv_one, 8, 6, 55                    'read the interview date
            If cash_intv_one <> "__ __ __" Then                     'if it is not blank
                cash_intv_one = replace(cash_intv_one, " ", "/")    'convert it to an actual date
                cash_interview_done = TRUE                          'define that the interview for cash has been done
            Else
                cash_intv_one = ""
            End If
        ElseIf cash_stat_one = "ACTV" Then
            ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = "Active" 'setting the array to identify that cash is active
        End If

        'it is impportant that line 2 is looked at second because we could ahve an active cash program BUT line 2 indicates that another cash program is PENDING
        'having line 2 second will overwrite the line 1 happennings.
        If cash_stat_two = "PEND" Then                              'otherwirse, if the second cash line indicated pending, we will look at that line for information
            cash_pend = TRUE                                        'note that cash is pending
            EMReadScreen cash_intv_two, 8, 7, 55                    'reading the interview date
            If cash_intv_two <> "__ __ __" Then                     'will convert to a date
                cash_intv_two = replace(cash_intv_two, " ", "/")
                cash_interview_done = TRUE                          'dfines that n interview is done
            Else
                cash_intv_two = ""                                  'making that blank interview date a true blank
            End If
        ElseIf cash_stat_two = "ACTV" Then
            ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = "Active" 'setting the array to identify that cash is active'
        End If

        If cash_pend = TRUE then ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = "Pending"       'setting the cash status if a pending cash was found

        If fs_pend = "PEND" Then                                            'if the SNAP status is pending
            ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) = "Pending"    'define the pending status in the ARRAY
            EMReadScreen fs_intv, 8, 10, 55                                 'read the interview date and reformat
            If fs_intv <> "__ __ __" Then
                fs_intv = replace(fs_intv, " ", "/")
                snap_interview_done = TRUE                                  'define the interview done
            Else
                fs_intv = ""
            End If
        ElseIf fs_pend = "ACTV" Then        'setting the correct infomration in the array otherwise
            ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) = "Active"
        Else
            ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) = ""
        End If

        'Here we have a chain of logic that will help to identify if what needs to happen from this point on
        'first, something needs to be PENDING for this process to apply - if neither are pending - we need to get rid of it
        If ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) <> "Pending" AND ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) <> "Pending" Then
            ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "REMOVE FROM LIST"            'set this variable because we can't just delete it now - the rows have all been defined to the array and everything will get messed up
            ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = "Neither SNAP nor CASH is pending."  'explain the removal - the case will be dleted at tomorrow's run
        Else                                                                                        'if one of these is pending
            If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "REVIEW DENIAL" Then       'this should only be this way if the denial was for yesterday - if the denial was correctly processed then it should have been removed from the list at the beginning
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "*** DENY ***"            'resetting the information to disaplay to call out that this is a problem case
                ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = "Denial Failed"
            End If
            If cash_pend = TRUE Then                    'for cash pending cases - there are some potential additional complications
                If cash_interview_done = TRUE Then      'if the cash interview was done - then even if SNAP is pending - the interview should have been compelted
                    If cash_intv_one <> "" Then ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = cash_intv_one     'setting the interview date from what was found in PROG
                    If cash_intv_two <> "" Then ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = cash_intv_two
                    ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = ""     'this is always blank if the cash interview has been completed
                    ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "NONE - Interview Completed"
                Else                                    'if the cash interview was NOT done
                    If fs_pend = "PEND" Then            'if this is SNAP pending case as well
                        If fs_intv = "" THen            'then if no interview for SNAP is indicated - neither is done
                            ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = ""
                        Else                            'if the SNAP interview was done but the cash one was not then we need to identify if another interview is needed
                            ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = fs_intv       'first we set the interview date in the array because one WAS actually done
                            If ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "CHECK FOR F2F NEEDED"        'if the array does not inidcate if we know about the interview then the next action is to check for if a face to face is needed
                            If ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "N" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "NONE - Interview Completed" 'if the array indicates that NONE is needed then the interview is done and no additional information is needed and there is no other action the script should take
                            If ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "Y" Then                'if the array indicates that a face to face is still needed then we use other information in the array to determine next action
                                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30"
                                If ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI"
                                IF ALL_PENDING_CASES_ARRAY(sppt_notc_sent, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE"
                            End If
                            ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ", Cash interview incomplete."
                        End If
                    End If
                End If
            ElseIf fs_pend = "PEND" Then        'if SNAP is pending and cash is not then everything is much simpler
                If fs_intv <> "" Then           'if an interview is done we will set the interview date and action in the array and blank out the face to face needed information
                    ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = fs_intv
                    ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "NONE - Interview Completed"
                    ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = ""
                End If
            End If
        End If

        'this bit of logic determines if we need to continue looking at the case in STAT
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE      'cases where the script doesn't know the next action always needs more information from STAT
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE" Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE       'Cases where we need to send an appointment notice ALWAYS need further action
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" AND DateDiff("d", date, ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)) <= 1 Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE     'If we have to send a NOMI and it is the day before the appointment date - we need to get some additional informaion
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30" AND DateDiff("d", ALL_PENDING_CASES_ARRAY(application_date, case_entry), date) >= 29 Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE   'If we are going to be denying tomorrow, we need some additional information

        'Here we only go in to STAT to look at cases that need attention
        If ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE Then

            Call navigate_to_MAXIS_screen("CASE", "NOTE")       'First to case note to find what has ahppened'

            day_before_app = DateAdd("d", -1, ALL_PENDING_CASES_ARRAY(application_date, case_entry)) 'will set the date one day prior to app date'
            If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "CHECK FOR F2F NEEDED" Then        'if on PROG we determined that we need to find if F2F is needed - we can go look for certain notes
                note_row = 5        'these always need to be reset when looking at Case note
                note_date = ""
                note_title = ""
                appt_date = ""
                Do                  'this do-loop moves down the list of case notes - looking at each row in MAXIS
                    EMReadScreen note_date, 8, note_row, 6      'reading the date of the row
                    EMReadScreen note_title, 55, note_row, 25   'reading the header of the note
                    note_title = trim(note_title)               'trim it down

                    'if the note headers match any of the following then we can know if a face to face is needed or not - then we add that detail to the ARRAY
                    If left(note_title, 50) = "~ Application interview for cash is still needed ~" Then ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "Y"
                    If left(note_title, 52) = "~ MFIP face to face application interview required ~" Then ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "Y"
                    If left(note_title, 51) = "~ DWP face to face application interview required ~" Then ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "Y"
                    If note_title = "~ MFIP face to face application interview not required" Then ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "N"
                    If left(note_title, 52) = "~ CASH face to face application interview required ~" Then ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "Y"
                        'keeping this here if we need to add it in
                        'THIS IS THE CASE/NOTE FOR CLIENTS REQUIRING NO INTERVIEW'
                        ' ~ Application interview ~
                        ' * Client is in an IMD FACI and is not required to complete interview
                        ' ---
                        ' EWS Quality Improvement Team
                    IF note_date = "        " then Exit Do      'if the case is new, we will hit blank note dates and we don't need to read any further
                    note_row = note_row + 1                     'going to the next row to look at the next notws
                    IF note_row = 19 THEN                       'if we have reached the end of the list of case notes then we will go to the enxt page of notes
                        PF8
                        note_row = 5
                    END IF
                    EMReadScreen next_note_date, 8, note_row, 6 'looking at the next note date
                    IF next_note_date = "        " then Exit Do
                Loop until datevalue(next_note_date) < day_before_app 'looking ahead at the next case note kicking out the dates before app'
                If ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) <> "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = ""   'if we were able to determing if a face to face is needed or not then we will blank out the action needed
            End If
            go_to_top_of_notes      'this is a function defined above so that if we need to read for different notes we don't miss ones on the first pages if we went to PF8

            If ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = "" Then        'if the ARRAY and Working Excel does not have a date listed for  when the appt notice was sent, the script will go to case ntoes to look for one
                note_row = 5            'resetting the variables on the loop
                note_date = ""
                note_title = ""
                appt_date = ""
                Do
                    EMReadScreen note_date, 8, note_row, 6      'reading the note date
                    EMReadScreen note_title, 55, note_row, 25   'reading the note header
                    note_title = trim(note_title)

                    IF left(note_title, 35) = "~ Appointment letter sent in MEMO ~" then
                        ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = note_date
    				ElseIF left(note_title, 42) = "~ Appointment letter sent in MEMO for SNAP" then
                        ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = note_date
    				ElseIF left(note_title, 37) = "~ Appointment letter sent in MEMO for" then
    					EMReadScreen appt_date, 10, note_row, 63
    					appt_date = replace(appt_date, "~", "")
    				 	appt_date = trim(appt_date)
    					ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = appt_date
                        ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = note_date
                        'MsgBox ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
    				END IF

                    IF note_date = "        " then Exit Do
                    note_row = note_row + 1
                    IF note_row = 19 THEN
                        PF8
                        note_row = 5
                    END IF
                    EMReadScreen next_note_date, 8, note_row, 6
                    IF next_note_date = "        " then Exit Do
                Loop until datevalue(next_note_date) < day_before_app 'looking ahead at the next case note kicking out the dates before app'
            End If
            go_to_top_of_notes

            If ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = "" Then     'if the date the NOMI was sent is blank in the ARRAY/Working Excel - then we are going to check CASE NOTES for information
                note_row = 5
                note_date = ""
                note_title = ""
                appt_date = ""
                Do
                    EMReadScreen note_date, 8, note_row, 6
                    EMReadScreen note_title, 55, note_row, 25
                    note_title = trim(note_title)

                    IF note_title = "~ Client missed application interview, NOMI sent via sc" then ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = note_date
                    IF left(note_title, 32) = "**Client missed SNAP interview**" then ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = note_date
    				IF left(note_title, 32) = "**Client missed CASH interview**" then ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = note_date
    				IF left(note_title, 37) = "**Client missed SNAP/CASH interview**" then ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = note_date
    				IF note_title = "~ Client has not completed application interview, NOMI" then ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = note_date
                    IF note_title = "~ Client has not completed CASH APP interview, NOMI sen" then ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = note_date

                    IF note_date = "        " then Exit Do
                    note_row = note_row + 1
                    IF note_row = 19 THEN
                        PF8
                        note_row = 5
                    END IF
                    EMReadScreen next_note_date, 8, note_row, 6
                    IF next_note_date = "        " then Exit Do
                Loop until datevalue(next_note_date) < day_before_app 'looking ahead at the next case note kicking out the dates before app'
            End If

            'Resetting the action needed in the ARRAY if we have found dates in case notes
            If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE" AND ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) <> "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI"
            If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" AND ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) <> "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30"

            'resetting the action needed based on what is going on with the case if the action needed is not defined
            If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "" Then
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30"
                If ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI"
                If ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = "" THen ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE"
            End If

            'these are for cases where the appointemnt notice sent date is found but the actual appointment date was not found
            'the script will go in to MEMO to read the appointment date from the actual memo.
            If ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) <> "" AND ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = "" Then
                Call navigate_to_MAXIS_screen ("SPEC", "MEMO")

                'defining the right month to look for the MEMO for as this doesn't work with the NAV functions
                memo_mo = DatePart("m", ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry))
                memo_mo = right("00"&memo_mo, 2)
                memo_yr = DatePart("yyyy", ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry))
                memo_yr = right(memo_yr, 2)

                EmWriteScreen memo_mo, 3, 48        'writing in the correct footer month and year and going there
                EmWriteScreen memo_yr, 3, 53
                transmit

                'creating a variable in the MM/DD/YY format to compare with date read from MAXIS
                look_date = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
                CAll convert_to_mainframe_date(look_date, 2)

                'Loop through all the lines
                Do
                    EMReadScreen create_date, 8, memo_row, 19                 'Reading the date of each memo and the status
                    EMReadScreen print_status, 7, memo_row, 67
                    'MsgBox print_status
                    If create_date = look_date AND print_status = "Printed" Then   'MEMOs created the date the appointment notice was noted and has been printed is likely out memo
                        EmWriteScreen "X", memo_row, 16         'opening the memo
                        transmit
                        PF8                                     'going to the next page

                        EMReadScreen start_of_msg, 35, 15,12    'reading the first line of the message to see if it is the right one
                        If start_of_msg = "You recently applied for assistance" Then    'this is how the appt notices start
                            EMReadScreen date_in_memo, 10, 19, 47                       'reading the date that was listed in the memo
                            date_in_memo = trim(date_in_memo)                           'this formats the date because sometimes dates are 10 chacters and sometimges they are 8
                            ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = replace(date_in_memo, ".", "")
                            Pf3                     'leaving the message and the loop
                            Exit Do
                        End If
                        PF3
                    End If
                    memo_row = memo_row + 1           'Looking at next row'
                Loop Until create_date = "        "
            End If
        End If

        ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = FALSE      'default this for all cases so that there is no carryover from the previous loop
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" AND ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = "" Then MsgBox "This case needs a NOMI but script cannot find an appointment date."    'This is for testing - it has never come up - may need a new 'Action needed' for the release
        'If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" AND ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "Determine Appointment Date"

        'This logic will determine if we need to look for additional information - such as a case note that potentially indicates an interview has been done
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "" Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE          'If the script does not know what action to take still - we MUST loof for more information
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE" Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE           'we always need to take additional action if the next step is to send an appointment notice
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" AND DateDiff("d", date, ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)) <= 1 Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE         'Cases where we must send a NOMI and the appointment day is tomorrow or before.
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30" AND DateDiff("d", ALL_PENDING_CASES_ARRAY(application_date, case_entry), date) >= 29 Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE           'Cases where the next step is to deny and day 30 is tomorrow or before

        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "" Then MsgBox "Case Number: " & ALL_PENDING_CASES_ARRAY(case_number, case_entry) & vbNewLine & "Does not have an action to take!!!"           'This is here for testing but has never come up

        'For cases that need an action taken and we do not know an interview date - we will check the case notes for a note that indicates an interview may have happened
        If ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE and ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = "" Then
            Call navigate_to_MAXIS_screen("CASE", "NOTE")       'go to case note
            note_row = 5                                        'setting these for the beginning of the loop to look through all the notes
            start_dates = ""
            day_before_app = DateAdd("d", -1, ALL_PENDING_CASES_ARRAY(application_date, case_entry)) 'will set the date one day prior to app date
            'setting a variable of previously known questionable interview date(s) - this will be used to determine if anything changed
            If InStr(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), "~") <> 0 Then start_dates = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)            '
            If ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) <> "" Then
                Call convert_to_mainframe_date(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), 2)
                start_dates = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
            End If
            Do
                EMReadScreen note_date, 8, note_row, 6          'read date of the note
                EMReadScreen note_title, 55, note_row, 25       'read the title of the note
                note_title = trim(note_title)
                check_this_date = TRUE                          'setting this as the default.

                array_of_dates = ""                             'clearing the array from previous loops
                If InStr(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), "~") <> 0 Then             'if there is a ~ that means there is a list of dates
                    array_of_dates = split(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), "~")     'if there is a list then it should be split in to an array
                    If array_of_dates(0) <> "" Then
                        For each dates in array_of_dates
                            'MsgBox MAXIS_case_number & " - Date 2"
                            Call convert_to_mainframe_date(dates, 2)        'Excel always turns dates into m/d/yyyy but MAXIS always displays them as mm/dd/yy and they don't match if they are in these different formats
                            'MsgBox "Already known questionable date: " & dates & vbNewLine & "Note Date: " & note_date
                            if DateValue(dates) = DateValue(note_date) Then check_this_date = FALSE     'if the date of the note is already known to be a questionable interview then we won't even LOOK at the note title because it has already been reviewed.
                        Next
                    End If
                Else            'If there is no ~ then it isn't a list - either blank or a single date
                    'MsgBox "Already known questionable date: " & dates & vbNewLine & "Note Date: " & note_date
                    If ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) <> "" Then            'If the questionable interview date is not blank
                        Call convert_to_mainframe_date(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), 2)   'making it mm/dd/yy for comparison
                        'MsgBox "Already known questionable date: " & ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & vbNewLine & "Note Date: " & note_date
                        if DateValue(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)) = DateValue(note_date) Then check_this_date = FALSE        'if the already known questionable interview matches the date of the case notes then we will not assess the note
                    End If
                End If

                If check_this_date = TRUE Then 'if a questionable interview date is left on the spreadsheet - that means it has been reviewed and is NOT an interview.
                    'All of these notes are used when intervies are done HOWEVER sometimes these notes are made when there is NO interview so we cannot assume the interview has happened - a worker must actually review these questionable interviews
                    'We will also add the note date to the list of questionable interviews
                    IF left(note_title, 15) = "***Add program:" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 33) = "***Intake Interview Completed ***" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 40) = "***Reapplication Interview Completed ***" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 42) = "~ Interview Completed for SNAP ~" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 42) = "*client interviewed* onboarding processing" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 34) = "***Intake: pending mentor review**" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 23) = "~ Interview Completed ~" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 10) = "***Intake:" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(note_title, 24) = "~ Application interview ~" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", This case may not require an interview."
                    END IF
                    IF left(note_title, 33) = "***Intake Interview Completed ***" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Case Note suggests interview completed but interview not listed on PROG."
                    END IF
                    IF left(UCase(note_title), 51) = "Phone call from client re: Phone interview Complete" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Possible case note indicating an interview. If an interview happened, PROG was not updated and an incorrect script was used."
                    END IF
                    IF left(UCase(note_title), 41) = "Phone call from client re: SNAP interview" then
                        ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) & "~" & note_date
                        ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", Possible case note indicating an interview. If an interview happened, PROG was not updated and an incorrect script was used."
                    END IF
                End If

                'These will be reviewed regardless of if there are questionable interviews because they indicate a denial
                IF left(UCase(note_title), 19) = "----DENIED SNAP----" then ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", DENY SNAP case note"       'possible enhancement to only note this if SNAP status is active or pending
                IF left(UCase(note_title), 19) = "----DENIED CASH----" then ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", DENY CASH case note"       'possible enhancement to only note this if Cash status is active or pending
                IF left(UCase(note_title), 24) = "----DENIED SNAP/CASH----" then ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", DENY SNAP/CASH"   'possible enhancement to only note this if Cash and SNAP status is active or pending
        		IF left(note_title, 31) = "~ Denied CASH/SNAP via script ~" then ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", SCRIPT DENIAL ALREADY NOTED"
                IF left(note_title, 31) = "~ Denied CASH via script ~" then ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", SCRIPT DENIAL ALREADY NOTED"
                IF left(note_title, 26) = "~ Denied SNAP via script ~" then ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", SCRIPT DENIAL ALREADY NOTED"

                IF note_date = "        " then Exit Do      'for newer cases we might meet the end of the case notes before the date is prior to the app date - this accounts for that
                note_row = note_row + 1                     'go to the next row
                IF note_row = 19 THEN                       'go to the next page if the end of the page has been reached
                    PF8
                    note_row = 5
                END IF
                EMReadScreen next_note_date, 8, note_row, 6     'read what note is next to know when to exit
                IF next_note_date = "        " then Exit Do
            Loop until datevalue(next_note_date) < day_before_app 'looking ahead at the next case note kicking out the dates before app'

            If left(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), 1) = "~" Then ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) = right(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry), len(ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry))-1)     'triming off the left most ~ of the questionale interview dates
            if ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry) <> start_dates Then ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "REVIEW QUESTIONABLE INTERVIEW DATE(S)"     'if a new date was added it needs to be reviewed but if they are the same then we know they have been reviewed and we can continue with the correct action

        End If

        ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = FALSE      'resetting this as we are going to redetermine based on the new information

        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE" Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE       'always take action if appt notice is needed
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" AND DateDiff("d", date, ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)) <= 0 Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE         'if action is to send NOMI and the appointment date is today or in the past
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30" AND DateDiff("d", ALL_PENDING_CASES_ARRAY(application_date, case_entry), date) >= 30 Then ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE       'if action is to deny and day 30 is today or in the past

        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "" Then MsgBox "Case Number: " & ALL_PENDING_CASES_ARRAY(case_number, case_entry) & vbNewLine & "Does not have an action to take!!!"           'this is for but I have never seen it come up
    End If

    IF ALL_PENDING_CASES_ARRAY(error_notes, case_entry) <> "" THEN ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = right(ALL_PENDING_CASES_ARRAY(error_notes, case_entry), len(ALL_PENDING_CASES_ARRAY(error_notes, case_entry))- 2)     'removing the first ', ' from the error notes to make it be not weird
Next
back_to_SELF

'creating a new ARRAY of all the cases that we take an action on so that we can add them to a sheet in the daily list
Dim ACTION_TODAY_CASES_ARRAY()
ReDim ACTION_TODAY_CASES_ARRAY(error_notes, 0)

todays_cases = 0        'incrementer for adding to this new array

'this FOR-NEXT adds information back to Excel - so people need to STAY OUT
For case_entry = 0 to UBOUND(ALL_PENDING_CASES_ARRAY, 2)    'look at all the cases on the Working Excel
    MAXIS_case_number	= ALL_PENDING_CASES_ARRAY(case_number, case_entry)    'setting this for nav functions

    forms_to_swkr = ""      'setting these for the start a memo function
    forms_to_arep = ""
    memo_started = TRUE

    'MsgBox MAXIS_case_number & vbNewLine & "Take action: " & ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) & vbNewLine & "Next action: " & ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
    If ALL_PENDING_CASES_ARRAY(take_action_today, case_entry) = TRUE Then       'only the cases that we have determined need something today
        'TODO add MEMB for written language information

        Call navigate_to_MAXIS_screen("STAT", "MEMB")
        EMReadScreen language_code, 2, 13, 42
        ALL_PENDING_CASES_ARRAY(written_lang, case_entry) = language_code

        if ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = "Pending" then           'setting the language for the notices - Cash or SNAP or both
            if ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) = "Pending" then
                programs = "CASH/SNAP"
            else
                programs = "CASH"
            end if
        else
            programs = "SNAP"
        end if

        'Cases needing an Appointment Notice
        If ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND APPOINTMENT NOTICE" Then

            ' 'THIS IS FOR TESTING
            ' need_intv_date = dateadd("d", 7, ALL_PENDING_CASES_ARRAY(application_date, case_entry))
            ' If need_intv_date <= date then need_intv_date = dateadd("d", 7, date)
            '
            ' ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = need_intv_date
            '
            ' ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = date
            ' ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry) = "Y"
            ' ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI"
            '
            ' ReDim Preserve ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)
            ' ACTION_TODAY_CASES_ARRAY(case_number, todays_cases)         = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(client_name, todays_cases)         = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(worker_ID, todays_cases)           = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(SNAP_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(CASH_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(application_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(application_date, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(interview_date, todays_cases)      = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(questionable_intv, todays_cases)   = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(need_face_to_face, todays_cases)   = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(appt_notc_sent, todays_cases)      = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(appointment_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(nomi_sent, todays_cases)           = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(nomi_confirm, todays_cases)        = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(deny_day30, todays_cases)          = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(next_action_needed, todays_cases)  = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)         = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & " - " & "Appointment Notice Sent today"
            ' todays_cases = todays_cases + 1

            'THIS IS FOR REAL LIFE'
            need_intv_date = dateadd("d", 10, ALL_PENDING_CASES_ARRAY(application_date, case_entry))       'setting the appointment date - it should be 7 days from the date of application
            If need_intv_date <= date then need_intv_date = dateadd("d", 10, date)         'if this is today or in the past then we reset this for 7 days from today

            Call change_date_to_soonest_working_day(need_intv_date)

            last_contact_day = dateadd("d", 30, ALL_PENDING_CASES_ARRAY(application_date, case_entry))       'setting the date to enter on the NOMI of the day of denial
            'ensuring that we have given the client an additional10days fromt he day nomi sent'
            IF DateDiff("d", need_intv_date, last_contact_day) < 1 then last_contact_day = need_intv_date

            need_intv_date = need_intv_date & ""		'turns interview date into string for variable
            ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) = need_intv_date        'adding this date to the appointment date in the ARRAY

            CALL start_a_new_spec_memo_and_continue(memo_started)		'Writes the appt letter into the MEMO.
			IF memo_started = True THEN
                Select Case ALL_PENDING_CASES_ARRAY(written_lang, case_entry)
                    Case "07"   'Somali (2nd)
                        Call write_variable_in_SPEC_MEMO("Taariikhdu markey ahayd " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & ", Waxaad Degmada Hennepin ka codsataycaawimaad, waxaasw loo baahan yahay wareysi si loo hiregeliyo codsigaaga.")
                        Call write_variable_in_SPEC_MEMO("** Wareysiga waa in la dhammaystiro ka hor " & need_intv_date & " **")
                        Call write_variable_in_SPEC_MEMO("Si loo dhammaystiro wareysiga telefoonka, wac laynka taleefanka EZ 612-596-1300 inta u dhaxaysa 9:00 aroornimo ilaa 4:00 galabnimo Isniina ilaa Jimcaha.")
                        Call write_variable_in_SPEC_MEMO("* Waxaa dhici karta in lagu siiyo gargaarka SNAP 24 saac gudahood wareysiga kaddib.")
                        Call write_variable_in_SPEC_MEMO("Haddii aad rabto inaad samaysato ballan wareysi, wac 612-596-1300. Waxa kale oo aad iman kartaa mid ka mid ah lixda xafiis ee hoos ku qoran si loo sameeyo wareysi gof ahaaneed inta u dhexeeya 8 ilaa 4:30, Isniinta ilaa jmcaha.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 Th hrs: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Saacaduhu waa Isniinta - Jimcaha 8-4:30 haddii aan si kale loo sheegin.)")
                        Call write_variable_in_SPEC_MEMO("* Haddii aynaan war kaa helin inta ka horreyssa " & last_contact_day & " *")
                        Call write_variable_in_SPEC_MEMO("*              codsigaaga waa la diidi doonaa             *")
                        Call write_variable_in_SPEC_MEMO("Haddii aad codsaneyso barnaamijka lacagta caddaanka ah ee haweenka uurka leh ama caruurta yar yar, waxaa laga yaabaa inaad u baahato wareysi fool-ka-fool ah.")
                        Call write_variable_in_SPEC_MEMO("Qoraallada rabshadaha qoysaska waxaad ka heli kartaa")
                        Call write_variable_in_SPEC_MEMO("https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
                        Call write_variable_in_SPEC_MEMO("Waxaad kaloo codsan kartaa qoraalkan oo warqad ah.")

                    Case "01"   'Spanish (3rd)
                        CALL convert_date_to_day_first(ALL_PENDING_CASES_ARRAY(application_date, case_entry), day_first_app_date)
                        CALL convert_date_to_day_first(need_intv_date, day_first_intv_date)
                        CALL convert_date_to_day_first(last_contact_day, day_first_last_contact_date)

                        Call write_variable_in_SPEC_MEMO("Usted ha aplicado para recibir ayuda en el Condado de Hennepin el " & day_first_app_date & " y se requiere una entrevista para procesar su aplicación.")
                        Call write_variable_in_SPEC_MEMO("**La entrevista debe ser completada para el " & day_first_intv_date & ".**")
                        Call write_variable_in_SPEC_MEMO("Para completar una entrevista telefónica, llame a la línea de información EZ al 612-596-1300 entre las 9:00 a.m. y las 4:00 p.m. de lunes a viernes.")
                        Call write_variable_in_SPEC_MEMO("*Puede recibir los beneficios de SNAP dentro de las 24 horas de realizada la entrevista.")
                        Call write_variable_in_SPEC_MEMO("Si desea programar una entrevista, llame al 612-596-1300. También puede acercarse a cualquiera de las seis oficinas mencionadas debajo para tener una entrevista personal entre las 8 y las 4:30 de lunes a viernes.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 J h.: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Los horarios son de lunes a viernes de 8 a 4:30 a menos que se remarque lo contrario)")
                        Call write_variable_in_SPEC_MEMO(" **   Si no tenemos novedades suyas para el " & day_first_last_contact_date & "   **")
                        Call write_variable_in_SPEC_MEMO(" **             su aplicación será denegada              **")
                        Call write_variable_in_SPEC_MEMO("Si está aplicando para un programa para mujeres embarazadas o para niños menores, podría necesitar una entrevista en persona.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Los folletos de violencia doméstica están disponibles en")
                        Call write_variable_in_SPEC_MEMO("https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
                        Call write_variable_in_SPEC_MEMO("También puede solicitar una copia en papel.")

                    Case "02"   'Hmong (4th)
                        Call write_variable_in_SPEC_MEMO("Koj tau thov kev pab cuam los ntawm Hennepin County rau thaum " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & " Es yuav tsum tau tuaj xam phaj mas thiaj li yuav khiav koj cov ntaub ntawv.")
                        Call write_variable_in_SPEC_MEMO("** Txoj kev xam phaj mas yuav tsum tshwm sim ua ntej lub " & need_intv_date & ". **")
                        Call write_variable_in_SPEC_MEMO("Yog xam phaj hauv xov tooj, hu rau EZ Info Line ntawm 612-596-1300 thaum 9:00am thib 4:00pm hnub Mon txog Fri.")
                        Call write_variable_in_SPEC_MEMO("* Koj yuav tsim nyob tau cov kev pab SNAP uas siv tau 24 teev tom qab kev xam phaj.")
                        Call write_variable_in_SPEC_MEMO(" Yog hais tias koj xav teem tuaj xam phaj, hu 612-596-1300 Koj kuj tuaj tau rau ib lub ntawm rau lub hoob kas nyob hauv qab no tuaj xam phaj tim ntej muag thaum 8 thiab 4:30, hnub Monday txog Friday.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 Th hrs: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Cov sij hawm qhib yog M - F 8-4:30 tsis li mas yuav tsum qhia ua ntej)")
                        Call write_variable_in_SPEC_MEMO("** Yog hais tias peb tsis hnov koj teb ua ntej " & last_contact_day & " **")
                        Call write_variable_in_SPEC_MEMO("**    yuav tsis lees koj daim ntawv thov.     **")
                        Call write_variable_in_SPEC_MEMO("Yog hais tias koj thov nyiaj ntsuab rau cov poj niam uas cev xeeb tub los yog rau cov menyuam yaus, koj yuav tsum tuaj xam phaj tim ntsej muag.")
                        Call write_variable_in_SPEC_MEMO("   Cov ntaub ntawv qhia txog kev raug tsim txom los ntawm cov txheeb ze kuj muaj nyob rau ntawm")
                        Call write_variable_in_SPEC_MEMO("https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
                        Call write_variable_in_SPEC_MEMO("Koj kuj thov tau ib qauv thiab.")

                    Case "06"   'Russian (5th)
                        Call write_variable_in_SPEC_MEMO("Vy' obratilis' za pomosh'ju v okrug Xennepin " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & " u dlya obrabotki zayavleniya trebuetsya sobesedovanie.")
                        Call write_variable_in_SPEC_MEMO("** Sobesedovanie dolozhno by't' zaversheno k " & need_intv_date & ". ** ")
                        Call write_variable_in_SPEC_MEMO("Chtoby' zavershit' sobesedovanie po telefonom, pozbonite v Informaczionnuju liniju EZ po telefonu 612-596-1300 s 9:00 do 16:00 s ponedel'nika po pyatniczu.")
                        Call write_variable_in_SPEC_MEMO("** Vy' smozhete poluchit' vy'platu SNAP vtechenie 24 chasov posle niterv'ju.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Esli vy' xotite naznachit' sobesedovanie pozvonite po telefonu 612-596-1300. Vy' takzhe mozhete obratit'sya v ljubojiz shesti oficov. Dlya sobesedovanie s 8 i do 4:30, s ponedel'nika po pyatniczu.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 Th hrs: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Chasy priyoma s ponedel'nika po pyatniczu s 8 do 4:30, esli ne ukazano inoe.)")
                        Call write_variable_in_SPEC_MEMO("** Esli my' ne usly'shim ot vac do " & last_contact_day & " **")
                        Call write_variable_in_SPEC_MEMO("**    vashi zayavlenie budet otklonino.    **")
                        Call write_variable_in_SPEC_MEMO("Esli vy' podaete zayavku na poluchenie denezhnoj programmy' dlya beremenny'x zhenshhin ili nesovershennoletnix detej, vam mozhet potrebovat'sya lechnoe sobesedobanie.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Broshyupy' o nasilii v sem'e dostupny' po adresu https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG")
                        Call write_variable_in_SPEC_MEMO("Vy' takzhe mozhete zaprosit' bumazhnuyu kopiyu.")

                    ' Case "12"   'Oromo (6th)
                    '     'MsgBox "OROMO"
                    ' Case "03"   'Vietnamese (7th)
                    '     'MsgBox "VIETNAMESE"
                    Case Else  'English (1st)

                        Call write_variable_in_SPEC_MEMO("You applied for assistance in Hennepin County on " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & "")
                        Call write_variable_in_SPEC_MEMO("and an interview is required to process your application.")
                        Call write_variable_in_SPEC_MEMO(" ")
                        Call write_variable_in_SPEC_MEMO("** The interview must be completed by " & need_intv_date & ". **")
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

                End Select
                ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry) = date
                PF4
			ELSE
				ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry) = "N" 'Setting this as N if the MEMO failed
			END IF

            If ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry) <> "N" Then Call confirm_memo_waiting(ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry))       'reading that a MEMO exists to confirm the notice went

            If ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry) = "N" Then              'if the MEMO failed we need to send it manually
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "Send Manual Appt Notice"
            ElseIf ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry) = "Y" Then               'if the memo was successful then we will changed the next action needed and we will create a case note
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI"
                Call start_a_blank_case_note

                Call write_variable_in_CASE_NOTE("~ Appointment letter sent in MEMO for " & need_intv_date & "~")
                Call write_variable_in_CASE_NOTE("* A notice has been sent via SPEC/MEMO informing the client of needed interview.")
                Call write_variable_in_CASE_NOTE("* Households failing to complete the interview within 30 days of the date they file an application will receive a denial notice")
                Call write_variable_in_CASE_NOTE("* A link to the domestic violence brochure sent to client in SPEC/MEMO as a part of interview notice.")
                Call write_variable_in_CASE_NOTE("---")
                Call write_variable_in_CASE_NOTE(worker_signature & " via bulk on demand waiver script")
                'MsgBox "What casenote was sent?"
                PF3

            Else
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "???"       'if the memo confirm is not N or Y then this next action holder is here for testing
            End If
            Call back_to_SELF

            'Adding the notice to the array of cases taken action on today
            ReDim Preserve ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)
            ACTION_TODAY_CASES_ARRAY(case_number, todays_cases)         = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
            ACTION_TODAY_CASES_ARRAY(client_name, todays_cases)         = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
            ACTION_TODAY_CASES_ARRAY(worker_ID, todays_cases)           = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
            ACTION_TODAY_CASES_ARRAY(SNAP_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
            ACTION_TODAY_CASES_ARRAY(CASH_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
            ACTION_TODAY_CASES_ARRAY(application_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(application_date, case_entry)
            ACTION_TODAY_CASES_ARRAY(interview_date, todays_cases)      = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
            ACTION_TODAY_CASES_ARRAY(questionable_intv, todays_cases)   = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
            ACTION_TODAY_CASES_ARRAY(need_face_to_face, todays_cases)   = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
            ACTION_TODAY_CASES_ARRAY(appt_notc_sent, todays_cases)      = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
            ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
            ACTION_TODAY_CASES_ARRAY(appointment_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
            ACTION_TODAY_CASES_ARRAY(nomi_sent, todays_cases)           = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
            ACTION_TODAY_CASES_ARRAY(nomi_confirm, todays_cases)        = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
            ACTION_TODAY_CASES_ARRAY(deny_day30, todays_cases)          = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry)
            ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
            ACTION_TODAY_CASES_ARRAY(next_action_needed, todays_cases)  = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
            ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)         = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & " - " & "Appointment Notice Sent today"
            todays_cases = todays_cases + 1       'increasing the counter for the array


        ElseIf ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "SEND NOMI" Then       'These cases need NOMIs

            ' 'THIS IS FOR TESTING'
            ' ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = date
            ' ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry) = "Y"
            ' ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30"
            ' ReDim Preserve ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)
            ' ACTION_TODAY_CASES_ARRAY(case_number, todays_cases)         = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(client_name, todays_cases)         = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(worker_ID, todays_cases)           = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(SNAP_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(CASH_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(application_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(application_date, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(interview_date, todays_cases)      = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(questionable_intv, todays_cases)   = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(need_face_to_face, todays_cases)   = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(appt_notc_sent, todays_cases)      = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(appointment_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(nomi_sent, todays_cases)           = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(nomi_confirm, todays_cases)        = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(deny_day30, todays_cases)          = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(next_action_needed, todays_cases)  = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
            ' ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)         = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & " - " & "NOMI Sent today"
            ' todays_cases = todays_cases + 1

            'THIS IS FOR REAL LIFE'
            nomi_last_contact_day = dateadd("d", 30, ALL_PENDING_CASES_ARRAY(application_date, case_entry))       'setting the date to enter on the NOMI of the day of denial
            'ensuring that we have given the client an additional10days fromt he day nomi sent'
            IF DateDiff("d", ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry), nomi_last_contact_day) < 1 then nomi_last_contact_day = dateadd("d", 10, ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry))

            CALL start_a_new_spec_memo_and_continue(memo_started)		'Writes the NOMI into the MEMO.
            IF memo_started = TRUE THEN
                Select Case ALL_PENDING_CASES_ARRAY(written_lang, case_entry)
                    Case "07"   'Somali (2nd)
                        Call write_variable_in_SPEC_MEMO("Waxdhawaan dalbatay caawinaad taariikhdu markay ahayd " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & ".")
                        Call write_variable_in_SPEC_MEMO("Wareysigaagu wuxuu ahaa in la dhammaystiro ka hor " & ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) & ".")
                        Call write_variable_in_SPEC_MEMO("Wareysi ayaa loo baahan yahay is loo hirgeliyo codsigaaga.")
                        Call write_variable_in_SPEC_MEMO("Si aad u dhamaystirto wareysiga telefoonka, wac laynka taleefanka EZ 612-596-1300 inta u dhaxaysa 9:00 subaxnimo ilaa 4:00 galabnimo Isniinta ilaa Jimcaha.")
                        Call write_variable_in_SPEC_MEMO("* Waxaa dhici karta in lagu siiyo gargaarka SNAP 24 saac gudahood wareysiga kaddib.")
                        Call write_variable_in_SPEC_MEMO("Haddii aad rabto inaad samaysato ballan wareysi, wac 612-596-1300. Waxa kale oo aad iman kartaa mid ka mid ah lixda xafiis ee hoos ku qoran si loo sameeyo wareysi gof ahaaneed inta u dhexeeya 8 ilaa 4:30, Isniinta ilaa jmcaha.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 Th hrs: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Saacaduhu waa Isniinta - Jimcaha 8-4:30 haddii aan si kale loo sheegin.)")
                        Call write_variable_in_SPEC_MEMO("* Haddii aynaan war kaa helin inta ka horreyssa " & nomi_last_contact_day & " *")
                        Call write_variable_in_SPEC_MEMO("*              codsigaaga waa la diidi doonaa             *")
                        Call write_variable_in_SPEC_MEMO("Haddii aad codsaneyso barnaamijka lacagta caddaanka ah ee haweenka uurka leh ama caruurta yar yar, waxaa laga yaabaa inaad u baahato wareysi fool-ka-fool ah.")
                        Call write_variable_in_SPEC_MEMO("Qoraallada rabshadaha qoysaska waxaad ka heli kartaa")
                        Call write_variable_in_SPEC_MEMO("https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
                        Call write_variable_in_SPEC_MEMO("Waxaad kaloo codsan kartaa qoraalkan oo warqad ah.")

                    Case "01"   'Spanish (3rd)

                        CALL convert_date_to_day_first(ALL_PENDING_CASES_ARRAY(application_date, case_entry), day_first_app_date)
                        CALL convert_date_to_day_first(ALL_PENDING_CASES_ARRAY(appointment_date, case_entry), day_first_intv_date)
                        CALL convert_date_to_day_first(nomi_last_contact_day, day_first_nomi_last_contact_date)

                        Call write_variable_in_SPEC_MEMO("Usted ha aplicado recientemente para recibir ayuda en el Condado de Hennepin el " & day_first_app_date".")
                        Call write_variable_in_SPEC_MEMO("Su entrevista debió haber sido realizada para el " & day_first_intv_date & ".")
                        Call write_variable_in_SPEC_MEMO("Se requiere una entrevista para procesar su aplicación.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Para completar una entrevista telefónica, llame a la línea de información EZ al 612-596-1300 entre las 9:00 a.m. y las 4:00 p.m. de lunes a viernes.")
                        Call write_variable_in_SPEC_MEMO("*Puede recibir los beneficios de SNAP dentro de las 24 horas de realizada la entrevista.")
                        Call write_variable_in_SPEC_MEMO("Si desea programar una entrevista, llame al 612-596-1300. También puede acercarse a cualquiera de las seis oficinas mencionadas debajo para tener una entrevista personal entre las 8 y las 4:30 de lunes a viernes.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 J h.: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Los horarios son de lunes a viernes de 8 a 4:30 a menos que se remarque lo contrario)")
                        Call write_variable_in_SPEC_MEMO(" **   Si no tenemos novedades suyas para el " & day_first_nomi_last_contact_date & "   **")
                        Call write_variable_in_SPEC_MEMO(" **             su aplicación será denegada              **")
                        Call write_variable_in_SPEC_MEMO("Si está aplicando para un programa para mujeres embarazadas o para niños menores, podría necesitar una entrevista en persona.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Los folletos de violencia doméstica están disponibles en")
                        Call write_variable_in_SPEC_MEMO("https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
                        Call write_variable_in_SPEC_MEMO("También puede solicitar una copia en papel.")

                    ' Case "02"   'Hmong (4th)
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")
                    '     Call write_variable_in_SPEC_MEMO("")


                    Case "06"   'Russian (5th)
                        Call write_variable_in_SPEC_MEMO("Vy' podali zayavlenie na pomoshh' 7/12/2018.")
                        Call write_variable_in_SPEC_MEMO("Vashe sobesedovanie dolzhno by't' zaversheno k 7/19/2018.")
                        Call write_variable_in_SPEC_MEMO("Dlya obrabotki zayavleniya trebuetsya sobesedovanie.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Chtoby' zavershit' sobesedovanie po telefonom, pozbonite v Informaczionnuju liniju EZ po telefonu 612-596-1300 s 9:00 do 16:00 s ponedel'nika po pyatniczu.")
                        Call write_variable_in_SPEC_MEMO("** Vy' smozhete poluchit' vy'platu SNAP vtechenie 24 chasov posle niterv'ju.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Esli vy' xotite naznachit' sobesedovanie pozvonite po telefonu 612-596-1300. Vy' takzhe mozhete obratit'sya v ljubojiz shesti oficov. Dlya sobesedovanie s 8 i do 4:30, s ponedel'nika po pyatniczu.")
                        Call write_variable_in_SPEC_MEMO("- 7051 Brooklyn Blvd Brooklyn Center 55429")
                        Call write_variable_in_SPEC_MEMO("- 1011 1st St S Hopkins 55343")
                        Call write_variable_in_SPEC_MEMO("- 9600 Aldrich Ave S Bloomington 55420 Th hrs: 8:30-6:30 ")
                        Call write_variable_in_SPEC_MEMO("- 1001 Plymouth Ave N Minneapolis 55411")
                        Call write_variable_in_SPEC_MEMO("- 525 Portland Ave S Minneapolis 55415")
                        Call write_variable_in_SPEC_MEMO("- 2215 East Lake Street Minneapolis 55407")
                        Call write_variable_in_SPEC_MEMO("(Chasy priyoma s ponedel'nika po pyatniczu s 8 do 4:30, esli ne ukazano inoe.)")
                        Call write_variable_in_SPEC_MEMO("** Esli my' ne usly'shim ot vac do " & nomi_last_contact_day & " **")
                        Call write_variable_in_SPEC_MEMO("**    vashi zayavlenie budet otklonino.    **")
                        Call write_variable_in_SPEC_MEMO("Esli vy' podaete zayavku na poluchenie denezhnoj programmy' dlya beremenny'x zhenshhin ili nesovershennoletnix detej, vam mozhet potrebovat'sya lechnoe sobesedobanie.")
                        Call write_variable_in_SPEC_MEMO("")
                        Call write_variable_in_SPEC_MEMO("Broshyupy' o nasilii v sem'e dostupny' po adresu https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG")
                        Call write_variable_in_SPEC_MEMO("Vy' takzhe mozhete zaprosit' bumazhnuyu kopiyu.")


                    ' Case "12"   'Oromo (6th)
                    '     'MsgBox "OROMO"
                    ' Case "03"   'Vietnamese (7th)
                    '     'MsgBox "VIETNAMESE"
                    Case Else  'English (1st)

                        Call write_variable_in_SPEC_MEMO("You recently applied for assistance on " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & ".")
                        Call write_variable_in_SPEC_MEMO("Your interview should have been completed by " & ALL_PENDING_CASES_ARRAY(appointment_date, case_entry) & ".")
                        Call write_variable_in_SPEC_MEMO("An interview is required to process your application.")
                        Call write_variable_in_SPEC_MEMO(" ")
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
                        Call write_variable_in_SPEC_MEMO("  ** If we do not hear from you by " & nomi_last_contact_day & " **")
                        Call write_variable_in_SPEC_MEMO("  **    your application will be denied.     **") 'add 30 days
                        Call write_variable_in_SPEC_MEMO("If you are applying for a cash program for pregnant women or minor children, you may need a face-to-face interview.")
                        Call write_variable_in_SPEC_MEMO(" ")
                        Call write_variable_in_SPEC_MEMO("Domestic violence brochures are available at https://edocs.dhs.state.mn.us/lfserver/Public/DHS-3477-ENG.")
                        Call write_variable_in_SPEC_MEMO("You can also request a paper copy.  Auth: 7CFR 273.2(e)(3).")

                End Select
                ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) = date
                PF4
            Else
                ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry) = "N"   'if the MEMO didn't start then setting this for the ARRAY and Working Excel.
            End If

            If ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry) <> "N" Then Call confirm_memo_waiting(ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry))     'reading the SPEC/MEMO page to see that a MEMO for today is waiting.

            'Resetting the next action needed based on message success and writing the case note if successful
            If ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry) = "N" Then
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "Send Manual NOMI"
            ElseIf ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry) = "Y" Then
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30"
                Call start_a_blank_case_note
                If ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) <> "Pending" OR ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry) = "Y" Then
                    Call write_variable_in_CASE_NOTE("~ Client has not completed CASH APP interview, NOMI sent via script ~ ")
                Else
                    Call write_variable_in_CASE_NOTE("~ Client has not completed application interview, NOMI sent via script ~ ")
                End If
                Call write_variable_in_CASE_NOTE("* A notice was previously sent to client with detail about completing an interview. ")
                Call write_variable_in_CASE_NOTE("* Households failing to complete the interview within 30 days of the date they file an application will receive a denial notice")
                Call write_variable_in_CASE_NOTE("* A link to the domestic violence brochure sent to client in SPEC/MEMO as a part of interview notice.")
                Call write_variable_in_CASE_NOTE("---")
                Call write_variable_in_CASE_NOTE(worker_signature & " via bulk on demand waiver script")
                'MsgBox "What casenote was sent?"
                PF3
            Else
                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "???"           'this is for testing - this has never come up
            End If
            Call back_to_SELF

            'Adding this case to the list of cases that we took action on today
            ReDim Preserve ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)
            ACTION_TODAY_CASES_ARRAY(case_number, todays_cases)         = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
            ACTION_TODAY_CASES_ARRAY(client_name, todays_cases)         = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
            ACTION_TODAY_CASES_ARRAY(worker_ID, todays_cases)           = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
            ACTION_TODAY_CASES_ARRAY(SNAP_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
            ACTION_TODAY_CASES_ARRAY(CASH_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
            ACTION_TODAY_CASES_ARRAY(application_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(application_date, case_entry)
            ACTION_TODAY_CASES_ARRAY(interview_date, todays_cases)      = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
            ACTION_TODAY_CASES_ARRAY(questionable_intv, todays_cases)   = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
            ACTION_TODAY_CASES_ARRAY(need_face_to_face, todays_cases)   = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
            ACTION_TODAY_CASES_ARRAY(appt_notc_sent, todays_cases)      = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
            ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
            ACTION_TODAY_CASES_ARRAY(appointment_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
            ACTION_TODAY_CASES_ARRAY(nomi_sent, todays_cases)           = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
            ACTION_TODAY_CASES_ARRAY(nomi_confirm, todays_cases)        = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
            ACTION_TODAY_CASES_ARRAY(deny_day30, todays_cases)          = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry)
            ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
            ACTION_TODAY_CASES_ARRAY(next_action_needed, todays_cases)  = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
            ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)         = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & " - " & "NOMI Sent today"
            todays_cases = todays_cases + 1

        ElseIf ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "DENY AT DAY 30" Then
            IF datediff("d", ALL_PENDING_CASES_ARRAY(application_date, case_entry), date) >= 30 and ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = "" THEN       'confirming that these cases meet all the criteria for denial
                'MsgBox ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
                'IDEA - enhance the script to case note ON day 30 if the case is not denied for some reason.
                'IDEA - add some additional error notes or information to Denial Needed to the script for cases that are at or over day 30
                IF ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry) <> "" then    'confirming a NOMI was sent
                    day_30 = dateadd("d", 30, ALL_PENDING_CASES_ARRAY(application_date, case_entry))
                    IF datediff("d", ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry), date) >= 10 or datediff("d", ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry), day_30) > 0 THEN      'cases are either at day 30 or 10 days from when the NOMI was sent
                    'MsgBox datediff("d", ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry), date)
                        Call navigate_to_MAXIS_screen("REPT", "PND2")       'looking at PND2 to confirm day 30 AND look for MSA cases - which get 60 days
                        Row = 1
                        Col = 1
                        EMSearch MAXIS_case_number, row, col
                        EMReadScreen nbr_days_pending, 3, row, 50
                        nbr_days_pending = trim(nbr_days_pending)
                        nbr_days_pending = nbr_days_pending * 1
                        IF nbr_days_pending >= 30 THEN ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = TRUE

                        'We are going to check to see if MX identifies this case as MSA
                        If ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry) <> "Pending" and ALL_PENDING_CASES_ARRAY(CASH_status, case_entry) = "Pending" Then      'This checks for cash only pending
                            EMReadScreen cash_prog, 2, row, 56
                            If cash_prog = "MS" Then
                                ALL_PENDING_CASES_ARRAY(error_notes, case_entry) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & ", MSA pending only."     'adding explanation of why this wont deny at day 30'
                                If datediff("d", ALL_PENDING_CASES_ARRAY(application_date, case_entry), date) >= 60 and ALL_PENDING_CASES_ARRAY(interview_date, case_entry) = "" THEN   'for MSA cases - the denial day is day 60
                                    ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = TRUE
                                Else
                                    ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = FALSE
                                End If
                            End If
                        End If
                        back_to_SELF

                        ' 'THIS IS FOR TESTING'
                        ' If ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = TRUE Then
                        '
                        '     ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry) = "Y"
                        '     ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "REVIEW DENIAL"
                        '
                        '     ReDim Preserve ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)
                        '     ACTION_TODAY_CASES_ARRAY(case_number, todays_cases)         = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(client_name, todays_cases)         = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(worker_ID, todays_cases)           = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(SNAP_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(CASH_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(application_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(application_date, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(interview_date, todays_cases)      = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(questionable_intv, todays_cases)   = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(need_face_to_face, todays_cases)   = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(appt_notc_sent, todays_cases)      = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(appointment_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(nomi_sent, todays_cases)           = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(nomi_confirm, todays_cases)        = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(deny_day30, todays_cases)          = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(next_action_needed, todays_cases)  = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
                        '     ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)         = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & " - " & "DENY today"
                        '     todays_cases = todays_cases + 1
                        ' End If

                        'THIS IS FOR REAL'
                        'Cases identifed as needing a denial will have a MEMO sent with detail
                        'TODO add functionality to update REPT PND2 with an I for these cases
                        If ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = TRUE Then
                            nomi_last_contact_day = dateadd("d", 30, ALL_PENDING_CASES_ARRAY(application_date, case_entry))
                            'ensuring that we have given the client an additional10days fromt he day nomi sent'
                            IF DateDiff("d", ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry), nomi_last_contact_day) < 1 then nomi_last_contact_day = dateadd("d", 10, ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry))

                            CALL start_a_new_spec_memo_and_continue(memo_started)		'Writes the denial into the MEMO.
                			IF memo_started = True THEN
                				EMsendkey("************************************************************")
                				Call write_variable_in_SPEC_MEMO("We received your application on " & ALL_PENDING_CASES_ARRAY(application_date, case_entry) & ".")
                				Call write_variable_in_SPEC_MEMO("Your interview was not completed by " & nomi_last_contact_day & ".")
                				call write_variable_in_spec_memo("Due to failing to complete the interview within 30 days of your application date your case has been denied.")
                				Call write_variable_in_SPEC_MEMO("************************************************************")
                				PF4
                			ELSE
                				ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry) = "N"         'Setting this as N if the MEMO failed
                				'MsgBox "What memo was sent?"
                			END IF

                            If ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry) <> "N" Then Call confirm_memo_waiting(ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry))

                            If ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry) = "N" Then
                                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "Send DENY MEMO Manually"
                            ElseIf ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry) = "Y" Then   'this will case note the denial
                                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "REVIEW DENIAL"
                                Call start_a_blank_case_note

                                Call write_variable_in_case_note("~ Denied " & programs & " via script ~")
                                Call write_bullet_and_variable_in_case_note("Application date", ALL_PENDING_CASES_ARRAY(application_date, case_entry))
                                Call write_variable_in_case_note("* Reason for denial: interview was not completed timely.")
                                Call write_variable_in_case_note("* Confirmed client was provided sufficient 10 day notice.")
                                Call write_bullet_and_variable_in_case_note("NOMI sent to client on ", ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry))
                                Call write_variable_in_case_note("---")
                                Call write_variable_in_CASE_NOTE(worker_signature & " via bulk on demand waiver script")

                                'MsgBox "What casenote was sent?"
                                PF3
                            Else
                                ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry) = "???"       'for testing - has never happened
                            End If
                            'msgbox nbr_days_pending
                            Call back_to_SELF

                            'Adding this case to the array of cases acted upon today
                            ReDim Preserve ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)
                            ACTION_TODAY_CASES_ARRAY(case_number, todays_cases)         = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
                            ACTION_TODAY_CASES_ARRAY(client_name, todays_cases)         = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
                            ACTION_TODAY_CASES_ARRAY(worker_ID, todays_cases)           = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
                            ACTION_TODAY_CASES_ARRAY(SNAP_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
                            ACTION_TODAY_CASES_ARRAY(CASH_status, todays_cases)         = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
                            ACTION_TODAY_CASES_ARRAY(application_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(application_date, case_entry)
                            ACTION_TODAY_CASES_ARRAY(interview_date, todays_cases)      = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
                            ACTION_TODAY_CASES_ARRAY(questionable_intv, todays_cases)   = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
                            ACTION_TODAY_CASES_ARRAY(need_face_to_face, todays_cases)   = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
                            ACTION_TODAY_CASES_ARRAY(appt_notc_sent, todays_cases)      = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
                            ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
                            ACTION_TODAY_CASES_ARRAY(appointment_date, todays_cases)    = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
                            ACTION_TODAY_CASES_ARRAY(nomi_sent, todays_cases)           = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
                            ACTION_TODAY_CASES_ARRAY(nomi_confirm, todays_cases)        = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
                            ACTION_TODAY_CASES_ARRAY(deny_day30, todays_cases)          = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry)
                            ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, todays_cases)   = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
                            ACTION_TODAY_CASES_ARRAY(next_action_needed, todays_cases)  = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)
                            ACTION_TODAY_CASES_ARRAY(error_notes, todays_cases)         = ALL_PENDING_CASES_ARRAY(error_notes, case_entry) & " - " & "NOMI Sent today"
                            todays_cases = todays_cases + 1
                        End If
                    END IF
                END IF
            END IF

        End If

        'ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) & ""  'excel prefers this to be a string - sometimes
    End If
    row = ALL_PENDING_CASES_ARRAY(excel_row, case_entry)    'setting the excel row

    'Now all the new information is added back to the Working Excel sheet
    ObjWorkExcel.Cells(row, worker_id_col).Value = ALL_PENDING_CASES_ARRAY(worker_ID, case_entry)
    ObjWorkExcel.Cells(row, case_nbr_col).Value = ALL_PENDING_CASES_ARRAY(case_number, case_entry)
    ObjWorkExcel.Cells(row, case_name_col).Value = ALL_PENDING_CASES_ARRAY(client_name, case_entry)
    ObjWorkExcel.Cells(row, snap_stat_col).Value = ALL_PENDING_CASES_ARRAY(SNAP_status, case_entry)
    ObjWorkExcel.Cells(row, cash_stat_col).Value = ALL_PENDING_CASES_ARRAY(CASH_status, case_entry)
    ObjWorkExcel.Cells(row, app_date_col).Value = ALL_PENDING_CASES_ARRAY(application_date, case_entry)

    ObjWorkExcel.Cells(row, intvw_date_col).Value = ALL_PENDING_CASES_ARRAY(interview_date, case_entry)
    ObjWorkExcel.Cells(row, quest_intvw_date_col).Value = ALL_PENDING_CASES_ARRAY(questionable_intv, case_entry)
    ObjWorkExcel.Cells(row, ftof_still_need_col).Value = ALL_PENDING_CASES_ARRAY(need_face_to_face, case_entry)
    ObjWorkExcel.Cells(row, appt_notc_date_col).Value = ALL_PENDING_CASES_ARRAY(appt_notc_sent, case_entry)
    ObjWorkExcel.Cells(row, appt_date_col).Value = ALL_PENDING_CASES_ARRAY(appointment_date, case_entry)
    ObjWorkExcel.Cells(row, appt_notc_confirm_col).Value = ALL_PENDING_CASES_ARRAY(appt_notc_confirm, case_entry)
    ObjWorkExcel.Cells(row, nomi_date_col).Value = ALL_PENDING_CASES_ARRAY(nomi_sent, case_entry)
    ObjWorkExcel.Cells(row, nomi_confirm_col).Value = ALL_PENDING_CASES_ARRAY(nomi_confirm, case_entry)
    If ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) = TRUE Then
        ObjWorkExcel.Rows(row).Font.ColorIndex = 3  'Red'
        ObjWorkExcel.Rows(row).Font.Bold = TRUE
    End If
    ObjWorkExcel.Cells(row, need_deny_col).Value = ALL_PENDING_CASES_ARRAY(deny_day30, case_entry) & ""
    ObjWorkExcel.Cells(row, deny_notc_confirm_col).Value = ALL_PENDING_CASES_ARRAY(deny_memo_confirm, case_entry)
    ObjWorkExcel.Cells(row, next_action_col).Value = ALL_PENDING_CASES_ARRAY(next_action_needed, case_entry)

    ObjWorkExcel.Cells(row, correct_need_col) = ALL_PENDING_CASES_ARRAY(error_notes, case_entry)
    'ObjWorkExcel.Cells(row, ) = ALL_PENDING_CASES_ARRAY(, case_entry)
Next

'Now the script reopens the daily list that was identified in the beginning
call excel_open(file_selection_path, True, True, ObjExcel, objWorkbook)

'It creates a new worksheet and names it
ObjExcel.Worksheets.Add().Name = "Cases Removed From Working LIST"

'Then it creates column headers
ObjExcel.Cells(1, worker_id_col)        = "Worker ID"
ObjExcel.Cells(1, case_nbr_col)         = "Case Number"
ObjExcel.Cells(1, case_name_col)        = "Case Name"
ObjExcel.Cells(1, snap_stat_col)        = "SNAP"
ObjExcel.Cells(1, cash_stat_col)        = "CASH"
ObjExcel.Cells(1, app_date_col)         = "Application Date"
ObjExcel.Cells(1, intvw_date_col)       = "Interview Date"
ObjExcel.Cells(1, quest_intvw_date_col) = "Questionable Interview Date"
ObjExcel.Cells(1, ftof_still_need_col)  = "Face To Face Still Needed"
ObjExcel.Cells(1, appt_notc_date_col)   = "Appt Notice Sent"
ObjExcel.Cells(1, appt_date_col)        = "Appointment Date"
ObjExcel.Cells(1, appt_notc_confirm_col)= "Confirm"
ObjExcel.Cells(1, nomi_date_col)        = "NOMI Sent"
ObjExcel.Cells(1, nomi_confirm_col)     = "Confirm"
ObjExcel.Cells(1, need_deny_col)        = "Denial"
ObjExcel.Cells(1, deny_notc_confirm_col)= "Confirm"
ObjExcel.Cells(1, next_action_col)      = "Next Action"
ObjExcel.Cells(1, correct_need_col)     = "Detail"
' ObjExcel.Cells(1, action_worker_col)    =
' ObjExcel.Cells(1, action_sup_col)       =
' ObjExcel.Cells(1, email_sent_col)       =

ObjExcel.Rows(1).Font.Bold = TRUE   'Making the header row bold

removed_row = 2     'setting a row counter
For case_removed = 0 to UBOUND(CASES_NO_LONGER_WORKING, 2)      'looping through each of the cases in the ARRAY from the beginning of cases that were taken off of the Working Excel
    If CASES_NO_LONGER_WORKING(error_notes, case_removed) = "" OR CASES_NO_LONGER_WORKING(client_name, case_removed) = "XXXXX" Then     'if we do not know WHY the case was removed or if the client's name is not filled in - we will go searching for a reason
        'PROG to determine programs active
        MAXIS_case_number = CASES_NO_LONGER_WORKING(case_number, case_removed)      'setting this for nav functions'
        CALL navigate_to_MAXIS_screen("CASE", "CURR")
        'Checking for PRIV cases.
        EMReadScreen priv_check, 6, 24, 14 'If it can't get into the case needs to skip
        EMReadScreen county_check, 2, 21, 16    'Looking to see if case has Hennepin COunty worker
        If priv_check = "PRIVIL" THEN       'idetifying PRIV cases '
            CASES_NO_LONGER_WORKING(error_notes, case_removed) = "PRIV"
        ElseIf county_check <> "27" THEN        'Identifying cases out of county -they would no longer show up on our BOBI and so would be removed from the Working Excel
            CASES_NO_LONGER_WORKING(error_notes, case_removed) = "Transferred out of county - " & county_check
        ElseIf CASES_NO_LONGER_WORKING(client_name, case_removed) = "XXXXX" Then        'Some priv cases we have access to - we can look up the names where the BOBI doesn't have them
            Call navigate_to_MAXIS_screen("STAT", "MEMB")       'Going to MEMB for 01
            EMReadScreen last_name, 25, 6, 30                   'getting name information
            EMReadScreen first_name, 12, 6, 63
            EMReadScreen middle_initial, 1, 6, 79

            last_name = replace(last_name, "_", "")             'reformatting
            first_name = replace(first_name, "_", "")
            middle_initial = replace(middle_initial, "_", "")

            CASES_NO_LONGER_WORKING(client_name, case_removed) = last_name & ", " & first_name & " " & middle_initial   'saving to the ARRAY in the same structure as the BOBI does
        End If

        If CASES_NO_LONGER_WORKING(error_notes, case_removed) = "" Then     'If we STILL don't know why the case was removed then we are going to look at PROG
        'most cases are removed because an interview has been completed OR SNAP/Cash have been acted upon

            Call navigate_to_MAXIS_screen("STAT", "PROG")       'this is the same code as above
            fs_intv = ""            'blanking out these variables
            cash_intv_one = ""
            cash_intv_two = ""
            CASES_NO_LONGER_WORKING(CASH_status, case_removed) = "" 'setting this a blank as we will reread it

            EMReadScreen cash_prog_one, 2, 6, 67    'reading each of the programs and statuses
            EMReadScreen cash_stat_one, 4, 6, 74

            EMReadScreen cash_prog_two, 2, 7, 67
            EMReadScreen cash_stat_two, 4, 7, 74

            EMReadScreen fs_pend, 4, 10, 74

            cash_pend = FALSE           'resetting these for each loop - we will look for TRUEs next
            cash_interview_done = FALSE
            snap_interview_done = FALSE

            If cash_stat_one = "PEND" Then      'if this is pending we will look for an interview date
                cash_pend = TRUE                'setting this to true
                EMReadScreen cash_intv_one, 8, 6, 55
                If cash_intv_one <> "__ __ __" Then     'formatting the date field read
                    cash_intv_one = replace(cash_intv_one, " ", "/")
                    cash_interview_done = TRUE
                Else
                    cash_intv_one = ""
                End If
            ElseIf cash_stat_one = "ACTV" Then      'if this is active - saving that to the ARRAY
                CASES_NO_LONGER_WORKING(CASH_status, case_removed) = "Active"
            End If

            If cash_stat_two = "PEND" Then      'if this is pending we will look for an interview date
                cash_pend = TRUE                'setting this to true
                EMReadScreen cash_intv_two, 8, 7, 55    'reading and formatting the date
                If cash_intv_two <> "__ __ __" Then
                    cash_intv_two = replace(cash_intv_two, " ", "/")
                    cash_interview_done = TRUE
                Else
                    cash_intv_two = ""
                End If
            ElseIf cash_stat_one = "ACTV" Then      'if active, setting that to the ARRAY
                CASES_NO_LONGER_WORKING(CASH_status, case_removed) = "Active"
            End If

            'Setting ARRAY if either case programs is pending
            If cash_pend = TRUE then CASES_NO_LONGER_WORKING(CASH_status, case_removed) = "Pending"

            If fs_pend = "PEND" Then    'if the SNAP is pending we are going to look for an interview
                CASES_NO_LONGER_WORKING(SNAP_status, case_removed) = "Pending"  'setting the status in the ARRAY
                EMReadScreen fs_intv, 8, 10, 55     'reading and formatting the interview date
                If fs_intv <> "__ __ __" Then
                    fs_intv = replace(fs_intv, " ", "/")
                    snap_interview_done = TRUE
                Else
                    fs_intv = ""
                End If
            ElseIf fs_pend = "ACTV" Then        'setting to active if SNAP is active
                CASES_NO_LONGER_WORKING(SNAP_status, case_removed) = "Active"
            Else
                CASES_NO_LONGER_WORKING(SNAP_status, case_removed) = ""
            End If

            'if nothing is pending then the application process is over
            If CASES_NO_LONGER_WORKING(SNAP_status, case_removed) <> "Pending" AND CASES_NO_LONGER_WORKING(CASH_status, case_removed) <> "Pending" Then
                CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "REMOVE FROM LIST"  'indicate in the ARRAY that there is no pening programs
                CASES_NO_LONGER_WORKING(error_notes, case_removed) = "Neither SNAP nor CASH is pending."
            Else                                'if either program is pending, we are going to look at interview logic
                If cash_pend = TRUE Then        'if cash is pending we will check for cash interviews first
                    If cash_interview_done = TRUE Then  'if the cash interview is done then the interview is done. and we will add the right information to the ARRAY
                        If cash_intv_one <> "" Then CASES_NO_LONGER_WORKING(interview_date, case_removed) = cash_intv_one
                        If cash_intv_two <> "" Then CASES_NO_LONGER_WORKING(interview_date, case_removed) = cash_intv_two
                        CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = ""
                        CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "NONE - Interview Completed"
                    Else        'if the cash interview is NOT done we are going to look for a possibel SNAP interview
                        If fs_pend = "PEND" Then        'this looks for a SNAP interview and then looks to see if we need a seperate Face to Face interview for the cash program
                            If fs_intv = "" THen
                                CASES_NO_LONGER_WORKING(interview_date, case_removed) = ""
                            Else
                                CASES_NO_LONGER_WORKING(interview_date, case_removed) = fs_intv
                                If CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = "" Then CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "CHECK FOR F2F NEEDED"
                                If CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = "N" Then CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "NONE - Interview Completed"
                                If CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = "Y" Then
                                    CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "DENY AT DAY 30"
                                    If CASES_NO_LONGER_WORKING(nomi_sent, case_removed) = "" Then CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "SEND NOMI"
                                    IF CASES_NO_LONGER_WORKING(sppt_notc_sent, case_removed) = "" Then CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "SEND APPOINTMENT NOTICE"
                                End If
                                CASES_NO_LONGER_WORKING(error_notes, case_removed) = ", Cash interview incomplete."
                            End If
                        End If
                    End If
                ElseIf fs_pend = "PEND" Then    'if cash is not pending but SNAP is, we will look for a SNAP interview
                    If fs_intv <> "" Then
                        CASES_NO_LONGER_WORKING(interview_date, case_removed) = fs_intv
                        CASES_NO_LONGER_WORKING(next_action_needed, case_removed) = "NONE - Interview Completed"
                        CASES_NO_LONGER_WORKING(need_face_to_face, case_removed) = ""
                    End If
                End If
            End If
        End If
    End If

    'making sure the script has the Excel Daily List up and saves the information about the case to the next blank row
    ObjExcel.Worksheets("Cases Removed From Working LIST").Activate
    'MsgBox "Row is " & removed_row & vbNewLine & "Worker ID " & CASES_NO_LONGER_WORKING(worker_ID, case_removed)
    ObjExcel.Cells(removed_row, worker_id_col).Value            = CASES_NO_LONGER_WORKING(worker_ID, case_removed)
    ObjExcel.Cells(removed_row, case_nbr_col).Value             = CASES_NO_LONGER_WORKING(case_number, case_removed)
    'CASES_NO_LONGER_WORKING(excel_removed_row, case_removed) = removed_row
    ObjExcel.Cells(removed_row, case_name_col).Value            = CASES_NO_LONGER_WORKING(client_name, case_removed)
    ObjExcel.Cells(removed_row, app_date_col).Value             = CASES_NO_LONGER_WORKING(application_date, case_removed)
    'CASES_NO_LONGER_WORKING(interview_date, case_removed) = ObjExcel.Cells(removed_row, intvw_date_col)
    ObjExcel.Cells(removed_row, intvw_date_col).Value           = CASES_NO_LONGER_WORKING(interview_date, case_removed)
    ObjExcel.Cells(removed_row, cash_stat_col).Value            = CASES_NO_LONGER_WORKING(CASH_status, case_removed)
    ObjExcel.Cells(removed_row, snap_stat_col).Value            = CASES_NO_LONGER_WORKING(SNAP_status, case_removed)

    ObjExcel.Cells(removed_row, appt_notc_date_col).Value       = CASES_NO_LONGER_WORKING(appt_notc_sent, case_removed)
    ObjExcel.Cells(removed_row, appt_notc_confirm_col).Value    = CASES_NO_LONGER_WORKING(appt_notc_confirm, case_removed)
    ObjExcel.Cells(removed_row, appt_date_col).Value            = CASES_NO_LONGER_WORKING(appointment_date, case_removed)
    ObjExcel.Cells(removed_row, nomi_date_col).Value            = CASES_NO_LONGER_WORKING(nomi_sent, case_removed)
    ObjExcel.Cells(removed_row, nomi_confirm_col).Value         = CASES_NO_LONGER_WORKING(nomi_confirm, case_removed)
    ObjExcel.Cells(removed_row, next_action_col).Value          = CASES_NO_LONGER_WORKING(next_action_needed, case_removed)
    ObjExcel.Cells(removed_row, quest_intvw_date_col).Value     = CASES_NO_LONGER_WORKING(questionable_intv, case_removed)
    ObjExcel.Cells(removed_row, ftof_still_need_col).Value     = CASES_NO_LONGER_WORKING(need_face_to_face, case_removed)

    ObjExcel.Cells(removed_row, correct_need_col).Value         = CASES_NO_LONGER_WORKING(error_notes, case_removed)

    'MsgBox removed_row & " = " & removed_row & " + 1"
    removed_row = removed_row + 1   'moving to the next row for the next loop
Next

'formatting the spreadsheet
For col_to_autofit =1 to  correct_need_col
    ObjExcel.Columns(col_to_autofit).AutoFit()
Next

'On the same Excel file the script creates a new sheet and names it
ObjExcel.Worksheets.Add().Name = "Actions Today"

'Header row is added
ObjExcel.Cells(1, worker_id_col)        = "Worker ID"
ObjExcel.Cells(1, case_nbr_col)         = "Case Number"
ObjExcel.Cells(1, case_name_col)        = "Case Name"
ObjExcel.Cells(1, snap_stat_col)        = "SNAP"
ObjExcel.Cells(1, cash_stat_col)        = "CASH"
ObjExcel.Cells(1, app_date_col)         = "Application Date"
ObjExcel.Cells(1, intvw_date_col)       = "Interview Date"
ObjExcel.Cells(1, quest_intvw_date_col) = "Questionable Interview Date"
ObjExcel.Cells(1, ftof_still_need_col)  = "Face To Face Still Needed"
ObjExcel.Cells(1, appt_notc_date_col)   = "Appt Notice Sent"
ObjExcel.Cells(1, appt_date_col)        = "Appointment Date"
ObjExcel.Cells(1, appt_notc_confirm_col)= "Confirm"
ObjExcel.Cells(1, nomi_date_col)        = "NOMI Sent"
ObjExcel.Cells(1, nomi_confirm_col)     = "Confirm"
ObjExcel.Cells(1, need_deny_col)        = "Denial"
ObjExcel.Cells(1, deny_notc_confirm_col)= "Confirm"
ObjExcel.Cells(1, next_action_col)      = "Next Action"
ObjExcel.Cells(1, correct_need_col)     = "Detail"
' ObjExcel.Cells(1, action_worker_col)    =
' ObjExcel.Cells(1, action_sup_col)       =
' ObjExcel.Cells(1, email_sent_col)       =

ObjExcel.Rows(1).Font.Bold = TRUE       'header row is bold

action_row = 2      'setting the first row
For action_case = 0 to UBOUND(ACTION_TODAY_CASES_ARRAY, 2)      'looping through the ARRAY created when we took actions on the cases on the Working Excel

    'removing leading seperators
    IF ACTION_TODAY_CASES_ARRAY(error_notes, action_case) <> "" AND left(ACTION_TODAY_CASES_ARRAY(error_notes, action_case), 3) = " - " THEN ACTION_TODAY_CASES_ARRAY(error_notes, action_case) = right(ACTION_TODAY_CASES_ARRAY(error_notes, action_case), len(ACTION_TODAY_CASES_ARRAY(error_notes, action_case))- 3)

    'adding the information from the ARRAY to the spreadsheet
    ObjExcel.Cells(action_row, worker_id_col)        = ACTION_TODAY_CASES_ARRAY(worker_ID, action_case)
    ObjExcel.Cells(action_row, case_nbr_col)         = ACTION_TODAY_CASES_ARRAY(case_number, action_case)
    ObjExcel.Cells(action_row, case_name_col)        = ACTION_TODAY_CASES_ARRAY(client_name, action_case)
    ObjExcel.Cells(action_row, snap_stat_col)        = ACTION_TODAY_CASES_ARRAY(SNAP_status, action_case)
    ObjExcel.Cells(action_row, cash_stat_col)        = ACTION_TODAY_CASES_ARRAY(CASH_status, action_case)
    ObjExcel.Cells(action_row, app_date_col)         = ACTION_TODAY_CASES_ARRAY(application_date, action_case)
    ObjExcel.Cells(action_row, intvw_date_col)       = ACTION_TODAY_CASES_ARRAY(interview_date, action_case)
    ObjExcel.Cells(action_row, quest_intvw_date_col) = ACTION_TODAY_CASES_ARRAY(questionable_intv, action_case)
    ObjExcel.Cells(action_row, ftof_still_need_col)  = ACTION_TODAY_CASES_ARRAY(need_face_to_face, action_case)
    ObjExcel.Cells(action_row, appt_notc_date_col)   = ACTION_TODAY_CASES_ARRAY(appt_notc_sent, action_case)
    ObjExcel.Cells(action_row, appt_notc_confirm_col)= ACTION_TODAY_CASES_ARRAY(appt_notc_confirm, action_case)
    ObjExcel.Cells(action_row, appt_date_col)        = ACTION_TODAY_CASES_ARRAY(appointment_date, action_case)
    ObjExcel.Cells(action_row, nomi_date_col)        = ACTION_TODAY_CASES_ARRAY(nomi_sent, action_case)
    ObjExcel.Cells(action_row, nomi_confirm_col)     = ACTION_TODAY_CASES_ARRAY(nomi_confirm, action_case)
    ObjExcel.Cells(action_row, need_deny_col)        = ACTION_TODAY_CASES_ARRAY(deny_day30, action_case)
    ObjExcel.Cells(action_row, deny_notc_confirm_col)= ACTION_TODAY_CASES_ARRAY(deny_memo_confirm, action_case)
    ObjExcel.Cells(action_row, next_action_col)      = ACTION_TODAY_CASES_ARRAY(next_action_needed, action_case)
    ObjExcel.Cells(action_row, correct_need_col)     = ACTION_TODAY_CASES_ARRAY(error_notes, action_case)

    action_row = action_row + 1     'go to the next row
Next

For col_to_autofit =1 to  correct_need_col      'formatting the sheet
    ObjExcel.Columns(col_to_autofit).AutoFit()
Next

script_end_procedure("It worked!")  'WE'RE DONE!
