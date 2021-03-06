'STATS GATHERING----------------------------------------------------------------------------------------------------
name_of_script = "BULK - DISA DR PEPR.vbs"
start_time = timer
STATS_counter = 1                       'sets the stats counter at one
STATS_manualtime = "100"                'manual run time in seconds
STATS_denomination = "C"       			'C is for each CASE
'END OF stats block==============================================================================================

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
call changelog_update("08/06/2018", "Updated script to work without a template file. Also updated back-end dialog handling.", "Ilse Ferris, Hennepin County")
call changelog_update("12/05/2017", "Defaulting footer month/year to current month plus one. Changed disa dates to their own columns.", "Ilse Ferris, Hennepin County")
call changelog_update("06/09/2017", "Initial version.", "Ilse Ferris, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'----------------------------------------------------------------------------------------------------custom function
Function HCRE_panel_bypass() 
	'handling for cases that do not have a completed HCRE panel
	PF3		'exits PROG to prommpt HCRE if HCRE insn't complete
	Do
		EMReadscreen HCRE_panel_check, 4, 2, 50
		If HCRE_panel_check = "HCRE" then
			PF10	'exists edit mode in cases where HCRE isn't complete for a member
			PF3
		END IF
	Loop until HCRE_panel_check <> "HCRE"
End Function

'dialog
'The dialog is defined in the loop as it can change as buttons are pressed 
BeginDialog file_selection_dialog, 0, 0, 266, 110, "DISA Dr. PEPR"
    ButtonGroup ButtonPressed
    PushButton 200, 45, 50, 15, "Browse...", select_a_file_button
    OkButton 145, 90, 50, 15
    CancelButton 200, 90, 50, 15
    EditBox 15, 45, 180, 15, file_selection_path
    GroupBox 10, 5, 250, 80, "Using the DISA DR. PEPR script"
    Text 20, 20, 235, 20, "This script should be used when the DISA PEPR messages are run, and additional information needs to be added (for Charles). "
    Text 15, 65, 230, 15, "Select the Excel file that contains the PEPR information by selecting the 'Browse' button, and finding the file."
EndDialog

'THE SCRIPT----------------------------------------------------------------------------------------------------
'Connects to BlueZone
EMConnect ""

Do
    'Initial Dialog to determine the excel file to use, column with case numbers, and which process should be run
    'Show initial dialog
    Do
    	Dialog file_selection_dialog
    	If ButtonPressed = cancel then stopscript
    	If ButtonPressed = select_a_file_button then call file_selection_system_dialog(file_selection_path, ".xlsx")
    Loop until ButtonPressed = OK and file_selection_path <> ""
    If objExcel = "" Then call excel_open(file_selection_path, True, True, ObjExcel, objWorkbook)  'opens the selected excel file'
    CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
Loop until are_we_passworded_out = false					'loops until user passwords back in

objExcel.Cells(1, 7).Value = "Action"
objExcel.Cells(1, 8).Value = "CASH"
objExcel.Cells(1, 9).Value = "SNAP"
objExcel.Cells(1, 10).Value = "HC"
objExcel.Cells(1, 11).Value = "GRH"
objExcel.Cells(1, 12).Value = "DISA Start"
objExcel.Cells(1, 13).Value = "DISA End"
objExcel.Cells(1, 14).Value = "WREG"
objExcel.Cells(1, 15).Value = "Total TANF mo."
objExcel.Cells(1, 16).Value = "60 Mo. Ext. RSN"

For i = 1 to 16
    objExcel.Cells(1, i).Font.Bold = True		'bold font'
    ObjExcel.columns(i).NumberFormat = "@" 		'formatting as text
    objExcel.Columns(i).AutoFit()				'sizing the columns'
Next 

'defaulting the footer month/year to current month plus one
back_to_self
EMWriteScreen CM_plus_1_mo, 20, 43
EMWriteScreen CM_plus_1_yr, 20, 46

excel_row = 2

DO  
    'Grabs the case number
	MAXIS_case_number = objExcel.cells(excel_row, 2).value
    If MAXIS_case_number = "" then exit do
	back_to_self

	'CASH 
	Call navigate_to_MAXIS_screen("STAT", "PROG")
	'Checking for PRIV cases.
	EMReadScreen priv_check, 6, 24, 14 'If it can't get into the case needs to skip
	IF priv_check <> "PRIVIL" THEN 	
	    EMReadScreen cash_prog_status_1, 4, 6, 74
	    if cash_prog_status_1 = "ACTV" then
            EMReadScreen cash_type, 2, 6, 67
	    	cash_prog_status = cash_type
	    Else 
	    	EMReadScreen cash_prog_status_2, 4, 7, 74
	    	IF cash_prog_status_2 <> "ACTV" then cash_prog_status = ""
            EMReadScreen cash_type, 2, 7, 67
	    	cash_prog_status = cash_type
	    End if 	
	    ObjExcel.Cells(excel_row, 8).Value = cash_prog_status
	    
	    'SNAP
	    EMReadScreen SNAP_prog_status, 4, 10, 74 
	    If SNAP_prog_status <> "ACTV" then SNAP_prog_status = ""
	    ObjExcel.Cells(excel_row, 9).Value = SNAP_prog_status
	    
	    'HC
	    EMReadScreen HC_prog_status, 4, 12, 74
	    If HC_prog_status <> "ACTV" then HC_prog_status = ""
	    ObjExcel.Cells(excel_row, 10).Value = HC_prog_status
	    
	    'GRH 
	    EMReadScreen GRH_prog_status, 4, 9, 74
	    If GRH_prog_status <> "ACTV" then GRH_prog_status = ""
	    ObjExcel.Cells(excel_row, 11).Value = GRH_prog_status
	    
		Call HCRE_panel_bypass
	    'Gathering the DISA Information 
	    Call navigate_to_MAXIS_screen("STAT", "DISA")
	    EMWriteScreen memb_number, 20, 76				'enters member number
	    transmit
	    EMReadScreen worker, 7, 21, 21
	    'Reading the disa dates
	    EMReadScreen disa_start_date, 10, 6, 47			'reading DISA dates
	    EMReadScreen disa_end_date, 10, 6, 69
	    disa_start_date = Replace(disa_start_date," ","/")		'cleans up DISA dates
	   	disa_end_date = Replace(disa_end_date," ","/")
		If disa_end_date = "__/__/____" then disa_end_date = ""
	   
	    ObjExcel.Cells(excel_row, 12).Value = disa_start_date
		ObjExcel.Cells(excel_row, 13).Value = disa_end_date
	    	
	    'Gathering the WREG Information
	    Call navigate_to_MAXIS_screen("STAT", "WREG")
	    EMReadScreen FSET_code, 2, 8, 50
		If FSET_code = "__" then FSET_code = ""
	    EMReadScreen ABAWD_code, 2, 13, 50		
		If ABAWD_code = "__" then ABAWD_code = ""
		
		If FSET_code = "" and ABAWD_code = "" then 
			WREG_code = ""
	    Else 
			WREG_code = FSET_code & "-" & ABAWD_code
		End if 
	    ObjExcel.Cells(excel_row, 14).Value = WREG_code
		
		Call navigate_to_MAXIS_screen("STAT", "TIME")
		EMReadScreen total_TANF_mo, 2, 17, 69
		EMReadScreen ext_60_mo, 2, 19, 31
		If ext_60_mo = "__" then ext_60_mo = ""
		ObjExcel.Cells(excel_row, 15).Value = trim(total_TANF_mo)
		ObjExcel.Cells(excel_row, 16).Value = ext_60_mo
	End if 
	
    MAXIS_case_number = ""
    excel_row = excel_row + 1
	STATS_counter = STATS_counter + 1
LOOP UNTIL objExcel.Cells(excel_row, 2).value = ""	'looping until the list of cases to check for recert is complete

FOR i = 1 to 16		'formatting the cells'
	objExcel.Columns(i).AutoFit()				'sizing the columns'
NEXT

script_end_procedure("Success! Please review the list generated.")		