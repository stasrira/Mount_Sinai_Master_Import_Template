VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clsFieldSettings"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public fieldName As String
Public FieldDefaultValue As String
Public FieldDefaultBool As Boolean
Public FieldErrorMessage As String
Public FieldRequiredBool As Boolean
Public FieldDropDownValueLookupRange As String
Public FieldDropDownBool As Boolean
Public DataAvailable As Boolean
Public FieldCalculated As Boolean
Public FieldCalcTrigger As Boolean
Public FieldCalcOverwriteExistingVal As Boolean
Public FieldDateType As Boolean
Public FieldExportAssignment As String
Public FieldNumericOnlyType As Boolean
Public FieldMiscSettings As String
Public FieldColumnNameOnRawData As String

Private FieldSettingsFirstCell As String 'sets to "A2" during initialization of the class
Private fieldRowNum As String 'Will hold address of the row containing the field on the FieldSettings sheet. This variable will be used from different Subs/Functions


Public Sub InitializeValues(cellProperties As clsCellProperties)  '(vFieldName As String)

    Dim iCols As Integer
    Dim r As Range

'for test only
'Debug.Print cellProperties.CellFieldName

    'Assign Field Value
    fieldName = cellProperties.CellFieldName 'vFieldName
    
    
    With Worksheets(cSettingsWorksheetName)
        Dim fnr As Range
        Dim iRows As Integer
        'Dim fn_row As String 'Will hold address of the row containing the field
        
        iRows = .UsedRange.rows.Count 'number of actually used rows
        
        'identify range of actually used cells on the given spreadsheet and apply Find function
        Set fnr = .Range(FieldSettingsFirstCell & ":" & Cells(iRows, 1).Address).Find(fieldName, LookIn:=xlValues, LookAt:=xlWhole)
        'Old code --> Set fnr = .Range(cFieldsRange).Find(fieldName, LookIn:=xlValues)
        If Not fnr Is Nothing Then
            DataAvailable = True 'update a flag to reflect that object can be safely used
            
            'fieldRowNum = Right(fnr.Address, Len(fnr.Address) - InStrRev(fnr.Address, "$") + 1) 'it will contain value presenting row of the record, i.e. $10
            fieldRowNum = "$" & fnr.row 'it will contain value presenting row of the record, i.e. $10
            
            'Populate values for all variables
            
'            'read Default field value
'            'Default value can be hardcoded for regular fields or retrieved through hardcoded VLookup function for dropdowns on FieldSettings sheet (the current version)
'            FieldDefaultValue = GetCellValueWithErrorCheck(.Range(cAddrDefault + fieldRowNum)) 'FieldDefaultValue = .Range(cAddrDefault + fieldRowNum).value
''TODO - retrieve default for dropdown fields from the range programmatically - it will be a more generic way of getting it
'
'            'read Default as boolean field value
'            FieldDefaultBool = Len(FieldDefaultValue) > 0 'FieldDefaultBool = Len(.Range(cAddrDefault + fieldRowNum).value) > 0
            
            'read DropDown field value
            FieldDropDownBool = GetCellValueWithErrorCheck(.Range(cAddrDropDown + fieldRowNum)) '.Range(cAddrDropDown + fieldRowNum).value
            'read error message value for no match of the dropdown field
            FieldErrorMessage = GetCellValueWithErrorCheck(.Range(cAddrDropdownErrorMessage + fieldRowNum)) '.Range(cAddrDropdownErrorMessage + fieldRowNum).value
            'read Dropdown lookup range (on the Dictionary sheet)
            FieldDropDownValueLookupRange = GetCellValueWithErrorCheck(.Range(cAddrDropDownValueLookupRange + fieldRowNum)) '.Range(cAddrDropDownValueLookupRange + fieldRowNum).value
            'read Date field value
            FieldDateType = GetCellValueWithErrorCheck(.Range(cAddrDateField + fieldRowNum)) '.Range(cAddrDateField + fieldRowNum).value
            'read exclude from export value
            FieldExportAssignment = GetCellValueWithErrorCheck(.Range(cAddrExportAssignment + fieldRowNum)) '.Range(cAddrExportAssignment + fieldRowNum).value
            'read Numeric Only value
            FieldNumericOnlyType = GetCellValueWithErrorCheck(.Range(cAddrNumericOnly + fieldRowNum)) '.Range(cAddrNumericOnly + fieldRowNum).value
            'read Misc_Settings value
            FieldMiscSettings = GetCellValueWithErrorCheck(.Range(cAddrMiscSettings + fieldRowNum)) '.Range(cAddrMiscSettings + fieldRowNum).value
            
            'get column letter of the current field as it will be present on the Validated sheet, i.e. A, B, AA, ...
            iCols = Worksheets(cValidatedWorksheetName).UsedRange.Columns.Count
            Set r = Worksheets(cValidatedWorksheetName).Range("A1:" & Cells(1, iCols).Address)
            On Error Resume Next
            'Address property will return value similar to $D$1; splitting it by '$' and taking element #1 to get a letter
            FieldColumnNameOnRawData = Split(r.Find(fieldName, LookIn:=xlValues).Address, "$")(1)
            On Error GoTo 0
            
            UpdateVolatileSettings cellProperties
            
            'read Required field value
            'Call function that will evaluate all volatile values - values that depends on values of other fileds
            'FieldRequiredBool = ValidateBoolValue(.Range(cAddrRequired + fieldRowNum).value, cellProperties)
            'UpdateVolatileSettings
            
            'read Calculated field value
            'FieldCalculated = .Range(cAddrCalculated + fieldRowNum).value
            'FieldCalculated = ValidateBoolValue(.Range(cAddrCalculated + fieldRowNum).value, cellProperties)
            
            'read Calculation Trigger field value
            'FieldCalcTrigger = .Range(cAddrCalcTrigger + fieldRowNum).value
            'FieldCalcTrigger = ValidateBoolValue(.Range(cAddrCalcTrigger + fieldRowNum).value, cellProperties)
            
        Else
            'TODO - Generate error message that the field name was not found
            DataAvailable = False
        End If
    End With
End Sub

'this function prevents cases when supplied formula for a needed values (on the Setting page) produces an error and cannot be evaluated. If that happens, value of ret_if_error variable will be returned
Private Function GetCellValueWithErrorCheck(cell As Range, Optional ret_if_error As String = "")
    If Not IsError(cell.value) Then
        GetCellValueWithErrorCheck = cell.value
    Else
        GetCellValueWithErrorCheck = ret_if_error
    End If
        
End Function

'This function will calculate volatile values for properties that depends on values of other fields
'This function is public since the FieldSettings objects stored in the dictFieldSettings dictionary will be required to re-evaluate volatile properties before each use.
Public Sub UpdateVolatileSettings(cellProperties As clsCellProperties) ', Optional ColumnToValidate As String = cAddrRequired
    Dim tmp As String
    
    If DataAvailable Then 'run the below code only if FieldSettings instance has data available
        With Worksheets(cSettingsWorksheetName)
            'read Default field value
            'Default value can be hardcoded for regular fields or retrieved through hardcoded VLookup function for dropdowns on FieldSettings sheet (the current version)
            FieldDefaultValue = EvalCellValueWithRef(GetCellValueWithErrorCheck(.Range(cAddrDefault + fieldRowNum)), cellProperties) 'GetCellValueWithErrorCheck(.Range(cAddrDefault + fieldRowNum)) 'FieldDefaultValue = .Range(cAddrDefault + fieldRowNum).value
            'TODO - retrieve default for dropdown fields from the range programmatically - it will be a more generic way of getting it

            'read Default as boolean field value
            FieldDefaultBool = Len(FieldDefaultValue) > 0 'FieldDefaultBool = Len(.Range(cAddrDefault + fieldRowNum).value) > 0
            
            'read Required field value
            'FieldRequiredBool = ValidateBoolValue(.Range(cAddrRequired + fieldRowNum).value, cellProperties)
            tmp = EvalCellValueWithRef(GetCellValueWithErrorCheck(.Range(cAddrRequired + fieldRowNum)), cellProperties)
            FieldRequiredBool = CBool(IIf(Len(Trim(tmp)) = 0, False, tmp))
            tmp = ""
            'read Calculated field value
            'FieldCalculated = ValidateBoolValue(.Range(cAddrCalculated + fieldRowNum).value, cellProperties)
            tmp = EvalCellValueWithRef(GetCellValueWithErrorCheck(.Range(cAddrCalculated + fieldRowNum)), cellProperties)
            FieldCalculated = CBool(IIf(Len(Trim(tmp)) = 0, False, tmp))
            tmp = ""
            'read Calculation Trigger field value
            'FieldCalcTrigger = ValidateBoolValue(.Range(cAddrCalcTrigger + fieldRowNum).value, cellProperties)
            tmp = EvalCellValueWithRef(GetCellValueWithErrorCheck(.Range(cAddrCalcTrigger + fieldRowNum)), cellProperties)
            FieldCalcTrigger = CBool(IIf(Len(Trim(tmp)) = 0, False, tmp))
            tmp = ""
            'read Calculation Overwrites Existing Values field value
            'FieldCalcOverwriteExistingVal = ValidateBoolValue(.Range(cAddrCalcOverwriteExistingVal + fieldRowNum).value, cellProperties)
            tmp = EvalCellValueWithRef(GetCellValueWithErrorCheck(.Range(cAddrCalcOverwriteExistingVal + fieldRowNum)), cellProperties)
            FieldCalcOverwriteExistingVal = CBool(IIf(Len(Trim(tmp)) = 0, False, tmp))
            tmp = ""
        End With
    End If
End Sub

Private Function ValidateBoolValue(vFormulaToValidate As String, cellProperties As clsCellProperties)
'IF ({MT_Project} = "MoTrPAC", 1, 0)
    
    If Len(vFormulaToValidate) > 0 Then
        'if passed value is not empty, try to validate it
        
        Dim regex As Object, str As String
        Dim matches As Object, match As Object
        
        'intiate regex object and pass there the search pattern
        Set regex = CreateObject("VBScript.RegExp")
        With regex
          .Pattern = "\{\w*\}" 'search for patterns of filed names inside fo the curved brackets, i.e. {MT_Project}
          .Global = True
        End With
             
        str = vFormulaToValidate
        'for test only:
        'str = "IF ({MT_Project} = ""MoTrPAC"" and {abc}, 1, 0)"
         
        If regex.Test(str) Then
            'if pattern was found, the found field names are needed to be filled with the actual field values from Validated sheet
            Set matches = regex.Execute(str)
                 
            For Each match In matches
              'Debug.Print match.value '{MT_Project}
              str = Replace(str, match.value, FindFieldValue(match.value, cellProperties))
              'str = Replace(str, match.value, FindFieldAddress(match.value, cellProperties.cellRow))
            Next match
        End If
        
        str = Replace(str, " ", "")
        
        'Evaluate value of the formula
        With Worksheets(cValidatedWorksheetName)
            If Not IsError(.Evaluate(str)) Then
                ValidateBoolValue = .Evaluate(str)
            Else
                ValidateBoolValue = False
            End If
            
        End With
    Else
        ValidateBoolValue = False
    End If
    
End Function

'this function identifies if other fields are referenced in cell value (of Field Settings tab) that is being evaluated. If it is, it will assume that any strings in curve parenthesis are field names
'and will attempt to get corresponded names. For example, {Project_Id} will be assumed a Project_Id column and value of this field corresponded to the current row will be retreived.
Public Function EvalCellValueWithRef(vFormulaToValidate As String, _
                                        cellProperties As clsCellProperties, _
                                        Optional worksheetToValidate As String = "") As String
'IF ({MT_Project} = "MoTrPAC", 1, 0)

    If Len(Trim(worksheetToValidate)) = 0 Then
        worksheetToValidate = cValidatedWorksheetName
    End If
        
    If Len(vFormulaToValidate) > 0 Then
        'if passed value is not empty, try to validate it
        
        Dim regex As Object, str As String
        Dim matches As Object, match As Object
        
        'intiate regex object and pass there the search pattern
        Set regex = CreateObject("VBScript.RegExp")
        With regex
          .Pattern = "\{(.*?)\}" '\{\w*\}" 'search for patterns of filed names inside fo the curved brackets, i.e. {MT_Project}
          .Global = True
        End With
             
        str = vFormulaToValidate
        'for test only:
        'str = "IF ({MT_Project} = ""MoTrPAC"" and {abc}, 1, 0)"
         
        If regex.Test(str) Then
            'if pattern was found, the found field names are needed to be filled with the actual field values from Validated sheet
            Set matches = regex.Execute(str)
                 
            For Each match In matches
              'Debug.Print match.value '{MT_Project}
              str = Replace(str, match.value, FindFieldValue(match.value, cellProperties, worksheetToValidate))
              'str = Replace(str, match.value, FindFieldAddress(match.value, cellProperties.cellRow))
            Next match
'        Else
'            str = CStr(str) '"""" + str + """"
        End If
        
        'Evaluate value of the formula
        With Worksheets(worksheetToValidate)
            If Not IsError(.Evaluate(str)) Then
                On Error Resume Next
                EvalCellValueWithRef = .Evaluate(str)
                On Error GoTo 0
            Else
                EvalCellValueWithRef = str
            End If
            
        End With
    Else
        EvalCellValueWithRef = vFormulaToValidate
    End If
    
End Function

'This function will return the actual value of the requested field. It will use the cellProperties object to identify the correct row to be used
Private Function FindFieldValue(fieldName As String, _
                                cellProperties As clsCellProperties, _
                                Optional targetWorksheet As String = "") As String
    'fieldName example: {MT_Project}
    'The following is using HLOOKUP function to find needed value - i.e. HLOOKUP("MT_Project", A1:Z100,4, FALSE)
    On Error Resume Next 'this is required to avoid run time errors, if HLookup cannot find a needed value
    
    If Len(Trim(targetWorksheet)) = 0 Then
        targetWorksheet = cValidatedWorksheetName
    End If
    
    fieldName = Replace(Replace(fieldName, "{", ""), "}", "") 'remove figure brackets from the name
    
    With Worksheets(targetWorksheet) '(cValidatedWorksheetName)
        Dim r As Variant, ur_addr As String
        r = Split(.UsedRange.Address, "$") ' identify used range on the sheet, i.e. $A$1:$AT$30 and split it to an array
        r(UBound(r)) = cellProperties.cellRow 'update row number of the last column of the range with the row number of the cell being used
        ur_addr = Join(r, "$") 'join the updated array back to a string
        
        'OLD code - FindFieldValue = CStr(Application.WorksheetFunction.HLookup(fieldName, .Range("A1:ZZ" & cellProperties.cellRow), cellProperties.cellRow, False))
        FindFieldValue = CStr(Application.WorksheetFunction.HLookup(fieldName, .Range(ur_addr), cellProperties.cellRow, False))
    End With

End Function


Private Sub Class_Initialize()
    FieldSettingsFirstCell = cFieldSettings_FirstFieldCell '"A2"
End Sub
