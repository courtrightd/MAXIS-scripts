'STATS GATHERING----------------------------------------------------------------------------------------------------
name_of_script = "BULK - UNEA UPDATER.vbs"
start_time = timer
STATS_counter = 1                          'sets the stats counter at one
STATS_manualtime = 335                      'manual run time in seconds
STATS_denomination = "C"       			   'C is for each CASE
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
CALL changelog_update("06/08/2018", "Removed custom function. This is now in the HC Functions Library. Updated back end dialog functionality and updated ", "Ilse Ferris, Hennepin County")
CALL changelog_update("02/05/2018", "Added additional handling for SPEC/MEMO sending, data validation and comments.", "Ilse Ferris, Hennepin County")
CALL changelog_update("12/29/2017", "Coordinates for sending MEMO's has changed in SPEC/MEMO. Updated script to support change.", "Ilse Ferris, Hennepin County")
call changelog_update("07/28/2017", "Initial version.", "Ilse Ferris, Hennepin County")

'Actually displays the changelog. This function uses a text file located in the My Documents folder. It stores the name of the script file and a description of the most recent viewed change.
changelog_display
'END CHANGELOG BLOCK =======================================================================================================

'The dialog is defined in the loop as it can change as buttons are pressed 
BeginDialog file_select_dialog, 0, 0, 221, 50, "Select the UNEA income source file"
    ButtonGroup ButtonPressed
    PushButton 175, 10, 40, 15, "Browse...", select_a_file_button
    OkButton 110, 30, 50, 15
    CancelButton 165, 30, 50, 15
    EditBox 5, 10, 165, 15, file_selection_path
EndDialog

'THE SCRIPT-------------------------------------------------------------------------------------------------------------------------
EMConnect ""		'Connects to BlueZone

'------------------------------------------------------------------------------------------------------establishing date variables
MAXIS_footer_month = CM_plus_1_mo
MAXIS_footer_year = CM_plus_1_yr

CM_minus_1_mo = right("0" & DatePart("m", DateAdd("m", -1, date)), 2)
CM_minus_1_yr = right(DatePart("yyyy", DateAdd("m", -1, date)), 2)

current_date = date
Call ONLY_create_MAXIS_friendly_date(current_date)			'reformatting the dates to be MM/DD/YY format to measure against the panel dates

'dialog and dialog DO...Loop	
Do
    'Initial Dialog to determine the excel file to use, column with case numbers, and which process should be run
    'Show initial dialog
    Do
        err_msg = ""
    	Dialog file_select_dialog
    	If ButtonPressed = cancel then stopscript
    	If ButtonPressed = select_a_file_button then call file_selection_system_dialog(file_selection_path, ".xlsx")
        If file_selection_path = "" then err_msg = err_msg & vbNewLine & "Use the Browse Button to select the file that has your client data"
        If err_msg <> "" Then MsgBox err_msg
    Loop until ButtonPressed = OK and file_selection_path <> ""
    If objExcel = "" Then call excel_open(file_selection_path, True, True, ObjExcel, objWorkbook)  'opens the selected excel file'
    CALL check_for_password(are_we_passworded_out)			'function that checks to ensure that the user has not passworded out of MAXIS, allows user to password back into MAXIS
Loop until are_we_passworded_out = false					'loops until user passwords back in

'Sets up the array to store all the information for each client'
Dim UNEA_array()
ReDim UNEA_array (10, 0)

'Sets constants for the array to make the script easier to read (and easier to code)'
Const case_num    	= 1			'Each of the case numbers will be stored at this position'
Const clt_pmi     	= 2
Const inc_type		= 3
Const claim_num   	= 4
Const act_claim		= 5
Const unea_amt 	  	= 6
Const cola_amt    	= 7
Const act_status  	= 8
Const act_notes   	= 9
Const Send_memo     = 10

'Now the script adds all the clients on the excel list into an array
excel_row = 2 're-establishing the row to start checking the members for
entry_record = 0
Do                                                            'Loops until there are no more cases in the Excel list
	MAXIS_case_number = objExcel.cells(excel_row, 1).Value          're-establishing the case numbers for functions to use
	If MAXIS_case_number = "" then exit do
	MAXIS_case_number = trim(MAXIS_case_number)
	
	client_PMI = objExcel.cells(excel_row, 2).value	'establishes client SSN
	'removing the 0's from the PMI number to match the formatting from MAXIS
	Do 
		client_PMI = trim(client_PMI)
		If left(client_PMI, 1) = "0" then client_PMI = right(client_PMI, len(client_PMI) - 1)
	Loop until left(client_PMI, 1) <> "0"
    
	income_type  	= objExcel.cells(excel_row,  9).value	'(col I) establishes income type code 
	claim_number 	= objExcel.cells(excel_row, 11).value	'(col K) establishes claim number from MAXIS (created by the report) 
    actual_claim 	= objExcel.cells(excel_row, 13).value	'(col M) establishes the acutal claim number (if another claim number was found by VA staff)
	unea_amount	 	= objExcel.cells(excel_row, 14).value	'(col N) establishes grant amount for each case
	cola_amount	 	= objExcel.cells(excel_row, 15).value	'(col O) establishes COLA amount for each case (if applicable)
	'cleaning up the variables
	income_type	 	= trim(income_type)
	claim_number 	= trim(claim_number)
    actual_claim    = trim(actual_claim)
	unea_amount		= trim(unea_amount)
	cola_amount 	= trim(cola_amount) 
	
	'Adding client information to the array'
	ReDim Preserve UNEA_array(10, entry_record)	'This resizes the array based on the number of rows in the Excel File'
	UNEA_array (case_num, 	entry_record) = MAXIS_case_number		'The client information is added to the array'
	UNEA_array (clt_PMI,  	entry_record) = client_PMI 
	UNEA_array (inc_type, 	entry_record) = income_type
    UNEA_array (claim_num,	entry_record) = claim_number
	UNEA_array (act_claim, 	entry_record) = actual_claim
	UNEA_array (unea_amt,   entry_record) = unea_amount 
	UNEA_array (cola_amt,   entry_record) = cola_amount
	UNEA_array (act_status, entry_record) = ""
	UNEA_array (act_notes,  entry_record) = ""
    UNEA_array (send_memo,  entry_record) = False 
	entry_record = entry_record + 1			'This increments to the next entry in the array'
	Stats_counter = stats_counter + 1
	excel_row = excel_row + 1
Loop

back_to_self
EMWriteScreen MAXIS_footer_month, 20, 43		'Writes in Current month plus one
EMWriteScreen MAXIS_footer_year, 20, 46		'Writes in Current month plus one's year

For i = 0 to Ubound(UNEA_array, 2)
	'Establishing values for each case in the array of cases 
	MAXIS_case_number	= UNEA_array (case_num, i)
	client_PMI			= UNEA_array (clt_PMI, i)
	income_type 		= UNEA_array (inc_type, i)
    actual_claim        = UNEA_array (act_claim, i)
	unea_amount 		= UNEA_array (unea_amt, i) 
	cola_amount 		= UNEA_array (cola_amt, i)
	
	If unea_amount = "" or IsNumeric(unea_amount) = False then 
		UNEA_array(act_status, i) = "Error"
		UNEA_array(act_notes, i) = "VA income amount is blank or is not numeric."
        UNEA_array(send_memo, i) = False
		income_panel_found = false 
	Else 
	    MAXIS_background_check()
        
        Call navigate_to_MAXIS_screen("CASE", "CURR")
        EMReadScreen active_case, 8, 8, 9
        If active_case = "INACTIVE" then 
            UNEA_array(act_status, i) = "Error"
            UNEA_array(act_notes, i) = "Case is inactive."
            UNEA_array(send_memo, i) = False
            income_panel_found = false 
        Else 
        
	        'Checking the SNAP status 
	        Call navigate_to_MAXIS_screen("STAT", "PROG")
	        EMReadScreen PRIV_check, 4, 24, 14					'if case is a priv case then it gets added to priv case list
	        If PRIV_check = "PRIV" then
	        	UNEA_array(act_status, i) = "Error"
	        	UNEA_array(act_notes, i) = "Case is privileged."
                UNEA_array(send_memo, i) = False
	        	income_panel_found = false 
	       
	        	'This DO LOOP ensure that the user gets out of a PRIV case. It can be fussy, and mess the script up if the PRIV case is not cleared.
	        	Do
	        		back_to_self
	        		EMReadScreen SELF_screen_check, 4, 2, 50	'DO LOOP makes sure that we're back in SELF menu
	        		If SELF_screen_check <> "SELF" then PF3
	        	LOOP until SELF_screen_check = "SELF"
	        	EMWriteScreen "________", 18, 43		'clears the case number
	        	transmit
	        Else 		
	            EMReadscreen county_code, 2, 21, 23
	            If county_code <> "27" then 
	            	UNEA_array(act_status, i) = "Error"
	            	UNEA_array(act_notes, i) = "Not Hennepin County case, county code is: " & county_code	'Explanation for the rejected report'
                    UNEA_array(send_memo, i) = False
	        		income_panel_found = false 
	            Else 
	        		'Reads to see if the client is on SNAP 
	            	EMReadscreen SNAP_active, 4, 10, 74
	            	If SNAP_active = "ACTV" or SNAP_active = "REIN" then 
	        			update_SNAP = True
	        		Else 
	        			update_SNAP = false
	        		End if
	        			
	        		'Reads to see if the client is on HC
	        		EMReadScreen HC_active, 4, 12, 74
	        		If HC_active = "ACTV" or HC_active = "REIN" then 
	        			update_HC = True
	        		Else 
	        			update_HC = false
	        		End if 
	        		
	        		'handling for cases that do not have a completed HCRE panel
	        		PF3		'exits PROG to prommpt HCRE if HCRE insn't complete
	        		Do
	        			EMReadscreen HCRE_panel_check, 4, 2, 50
	        			If HCRE_panel_check = "HCRE" then
	        				PF10	'exists edit mode in cases where HCRE isn't complete for a member
	        				PF3
	        			END IF
	        		Loop until HCRE_panel_check <> "HCRE"
	        		
	            	Call navigate_to_MAXIS_screen("STAT", "MEMB")
	            	Do 
	            		EMReadscreen client_PMI, 8, 4, 46
	            		client_PMI = trim(client_PMI)
	            		If client_PMI = UNEA_array(clt_PMI, i) then
	            			EMReadscreen member_number, 2, 4, 33
	        				exit do
	            		Else 
	            			transmit
	            		END IF
	            		EMReadScreen MEMB_error, 5, 24, 2
	            	Loop until client_PMI = UNEA_array (clt_SSN, i) or MEMB_error = "ENTER"
	        		
	            	IF client_PMI <> UNEA_array(clt_PMI, i) then 
	            		UNEA_array(act_status, i) = "Error"
	            		UNEA_array(act_notes, i) = "Unable to find person's member number."	'Explanation for the rejected report'
                        UNEA_array(send_memo, i) = False
	        			income_panel_found = false 
	            	Else 
	            		'STAT UNEA PORTION
	            		Call navigate_to_MAXIS_screen("STAT", "UNEA")
	        			EMWriteScreen member_number, 20, 76
	        			EMWriteScreen "01", 20, 79				'to ensure we're on the 1st instance of UNEA panels for the appropriate member
	        			transmit
	        			
	        			EMReadScreen total_amt_of_panels, 1, 2, 78	'Checks to make sure there are JOBS panels for this member. If none exists, one will be created
	        			If total_amt_of_panels = "0" then 
	        				UNEA_array(act_status, i) = "Error"
	        				UNEA_array(act_notes, i) = "UNEA panel not known. Review case, and update manually if applicable."	'Explanation for the rejected report'
                            UNEA_array(send_memo, i) = False
	        				income_panel_found = false 
	        			Else 	
	        				Do
	        					EMReadScreen current_panel_number, 1, 2, 73
	        					EMReadScreen income_type, 2, 5, 37
	        					If income_type = UNEA_array(inc_type, i) then
	        						income_panel_found = true 
	        						PF9
	        						
	        						'updates the SNAP PIC	
	        						If update_SNAP = true then 							
	        							Call write_value_and_transmit("x", 10, 26)
	        							Call create_MAXIS_friendly_date(date, 0, 5, 34)
	        							EMWriteScreen "1", 5, 64							'code for pay frequency
	        							row = 9											'blanking out the income fields on the PIC (just in case their is income listed there)
	        							Do 
	        								EMWriteScreen "__", row, 13
	        								EMWriteScreen "__", row, 16
	        								EMWriteScreen "__", row, 19
	        								EMWriteScreen "________", row, 25
	        								row = row + 1
	        							Loop until row = 14
	        							
	        							EMWriteScreen "________", 8, 66
	        							EMWriteScreen UNEA_array(unea_amt, i), 8, 66
	        							Do 
	        								transmit
	        								EMReadscreen UNEA_panel, 4, 2, 48
	        							Loop until UNEA_panel = "UNEA"
	        						End if 	
	        								
	        						'updates the HC pop up
	        						IF update_HC = true then							
	        							Call write_value_and_transmit("x", 6, 56)
	        							EMWriteScreen "________", 9, 65
	        							EMWriteScreen UNEA_array(unea_amt, i), 9, 65
	        							EMWriteScreen "1", 10, 63							'code for pay frequency
	        							Do 
	        								transmit
	        								EMReadscreen HC_popup, 9, 7, 41
	        								If HC_popup = "HC Income" then transmit
	        							Loop until HC_popup <> "HC Income"
	        						End if 
	        						'----------------------------------------------------------------------------------------------------UNEA panel updates
	        						EMWriteScreen "6", 5, 65				'Verification code for 'worker initiated verification'
	        						
	        						If UNEA_array(act_claim, i) <> "" then 		'If the case's claim number has been identified as being incorrect, the correct claim will be entered.
	        							EMWriteScreen "_______________", 6, 37
	        							EMWriteScreen UNEA_array(act_claim, i), 6, 37
	        						End if
	        						
	        						If UNEA_array(cola_amt, i) <> "" then 				'writes in the COLA amount if applicable
	        							EMWriteScreen "________", 10, 67
	        							EMWriteScreen UNEA_array(cola_amt, i), 10, 67
	        						End if
	        						
	        						'----------------------------------------------------------------------------------------------------RETROSPECTIVE
	        						EMReadscreen prospective_amt, 8, 13, 68
	        						prospective_amt = replace(prospective_amt, "_", "")
	        						
	        						row = 13			'blanking out all retrospective UNEA fields
	        						DO 	
	        							EMWriteScreen "__", row, 25
	        							EMWriteScreen "__", row, 28
	        							EMWriteScreen "__", row, 31
	        							EMWriteScreen "________", row, 39
	        							row = row + 1
	        						Loop until row = 18
	        						
	        						EMWriteScreen CM_minus_1_mo, 13, 25		'Entering the CM + 1 date 
	        						EMWriteScreen "01", 13, 28
	        						EMWriteScreen CM_minus_1_yr, 13, 31
	        						EMWriteScreen prospective_amt, 13, 39
	        						
	        						'----------------------------------------------------------------------------------------------------PROSPECTIVE 
	        						row = 13			'blanking out all prospective UNEA fields
	        						DO 
	        							EMWriteScreen "__", row, 54
	        							EMWriteScreen "__", row, 57
	        							EMWriteScreen "__", row, 60
	        							EMWriteScreen "________", row, 68
	        							row = row + 1
	        						Loop until row = 18
	        						
	        						EMWriteScreen CM_plus_1_mo, 13, 54		'Entering the CM + 1 date 
	        						EMWriteScreen "01", 13, 57
	        						EMWriteScreen CM_plus_1_yr, 13, 60
	        						
	        						EMWriteScreen UNEA_array(unea_amt, i), 13, 68		'Entering the income on the UNEA panel	
	        						transmit
	        						PF3 		'to exit the UNEA panel
	        						income_panel_found = True
	        						exit do 
	        					Else 
	        						transmit	'looking for another UNEA panel
	        					End if 
	        				Loop until current_panel_number = total_amt_of_panels
	        				
	        				If income_panel_found <> true then 
	        					UNEA_array(act_status, i) = "Error"
	        					UNEA_array(act_notes, i) = "Unable to find person's member number."	'Explanation for the rejected report'
	        					UNEA_array(send_memo, i) = False 
	        				End if 
	        				back_to_self		'to clear WRAP panel
	            		End if 
	            	End if 
	            End if 
	        End if 
        End if 
	End if 
	
	IF income_panel_found = true then		
	    start_a_blank_CASE_NOTE
	    '----------------------------------------------------------------------------------------------------THE CASE NOTE
	    renewal_period = MAXIS_footer_month & "/" & MAXIS_footer_year		'establishing the renewal period for the header of the case note
	
	    start_a_blank_CASE_NOTE
	    Call write_variable_in_CASE_NOTE("*" & renewal_period & " recert accuracy update for VA income*")
	    Call write_variable_in_CASE_NOTE("Do not update the following info unless a new change has been reported.")
	    Call write_variable_in_CASE_NOTE("* VA income: $" & UNEA_array(unea_amt, i) & " monthly grant.")
		Call write_variable_in_CASE_NOTE("* VA income has been verified via phone by Hennepin County Veterans Service Office staff.")
		call write_variable_in_case_note("* SPEC/MEMO sent to client re: questions about Veteran's benefits.")
	
		call write_variable_in_case_note("---")
		call write_variable_in_case_note(worker_signature)
		
		'ensuring that the case note saved. If not, adding it to the notes for the user to review. 
		PF3
		EMReadScreen note_date, 8, 5, 6
		If note_date <> current_date then 
			UNEA_array(act_status, i) = "Error"
			UNEA_array(act_notes, i) = "Case note does not appear to have been saved."	'Explanation for the rejected report'
			UNEA_array(send_memo, i) = False 
	    Else 
            UNEA_array(act_status, i) = "Case updated"
            UNEA_array(act_notes, i) = ""	'Explanation for the rejected report'
			UNEA_array(send_memo, i) = True 
		End if 	
	End if
Next    

For i = 0 to Ubound(UNEA_array, 2)
    If UNEA_array(send_memo, i) = True then 
        MAXIS_case_number = UNEA_array(case_num, i)
        Call MAXIS_background_check
        '----------------------------------------------------------------------------------------------------THE SPEC/MEMO
        Call start_a_new_spec_memo
        call navigate_to_MAXIS_screen("SPEC", "MEMO")		'Navigating to SPEC/MEMO
                
        'Writes the MEMO.
        call write_variable_in_SPEC_MEMO("If you have any questions about veterans benefits, please contact the Hennepin County Veterans Service Office at 612-348-3300. Veterans Services has staff at the Government Center, the South Minneapolis Human Service center, and Maple Grove. You may also make an appointment at a variety of regional locations.")
        Call write_variable_in_SPEC_MEMO("")
        Call write_variable_in_SPEC_MEMO("Even if you are already in receipt of compensation or pension, your benefit amount may be able to be increased.")
        Call write_variable_in_SPEC_MEMO("")
        Call write_variable_in_SPEC_MEMO("If you are interested in speaking with someone regarding Veterans benefits, or if you have questions about this notice, please call the Hennepin County Veterans Service Office at 612-348-3300. Thank you.")	
        PF4			'Exits the MEMO
        EMReadScreen memo_sent, 8, 24, 2
        If memo_sent <> "NEW MEMO" then 
            UNEA_array(act_status, i) = "Error"
            UNEA_array(act_notes, i) = "Does not appear that memo sent."	'Explanation for the rejected report'
            PF10
        End if 
    End if  
Next 
    
'Export data to Excel 
excel_row = 2
For i = 0 to Ubound(UNEA_array, 2)
	ObjExcel.Cells(Excel_row, 16).Value = UNEA_array(act_status, i) '(Col P)
	ObjExcel.Cells(Excel_row, 17).Value = UNEA_array(act_notes,  i) '(Col Q)
	Excel_row = Excel_row + 1
Next

Stats_counter = stats_counter + 1
script_end_procedure("Success! The list is complete. Please review the cases that appear to be in error.")