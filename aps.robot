*** Settings ***
Library           Selenium2Library
Library           String
Library           DateTime
Library           Collections
Library           Screenshot
Resource          APStender_subkeywords.robot
Library           aps_service.py
Resource          View.robot
Resource          Locators.robot

*** Keywords ***
Підготувати дані для оголошення тендера
    [Arguments]    ${username}    ${tender_data}
    ${tender_data}=    adapt_procuringEntity    ${tender_data}
    [Return]    ${tender_data}

Підготувати клієнт для користувача
    [Arguments]    @{ARGUMENTS}
    [Documentation]    [Documentation] \ Відкрити брaузер, створити обєкт api wrapper, тощо
    ...    ... \ \ \ \ \ ${ARGUMENTS[0]} == \ username
    Open Browser    ${USERS.users['${ARGUMENTS[0]}'].homepage}    ${USERS.users['${ARGUMENTS[0]}'].browser}    alias=${ARGUMENTS[0]}
    Set Window Size    @{USERS.users['${ARGUMENTS[0]}'].size}
    Set Window Position    @{USERS.users['${ARGUMENTS[0]}'].position}
    Run Keyword If    '${ARGUMENTS[0]}'!= 'aps_Viewer'    Login    @{ARGUMENTS}

Створити тендер
    [Arguments]    @{ARGUMENTS}
    [Documentation]    [Documentation]
    ...    ... \ \ \ \ \ ${ARGUMENTS[0]} == \ username
    ...    ... \ \ \ \ \ ${ARGUMENTS[1]} == \ tender_data
    Switch Browser    ${ARGUMENTS[0]}
    Return From Keyword If    '${ARGUMENTS[0]}' != 'aps_Owner'
    ${tender_data}=    Get From Dictionary    ${ARGUMENTS[1]}    data
    #
    WaitClickXPATH    ${locator.buttonAdd}
    WaitClickXPATH    ${locator.buttonTenderAdd}
    TenderInfo    ${tender_data}
    \    #
    Run Keyword And Ignore Error    WaitClickXPATH    .//div[@class="btn-group"]/label[2]
    Заповнити дати тендеру    ${tender_data.enquiryPeriod}    ${tender_data.tenderPeriod}
    \    #
    Execute Javascript    window.scroll(1500,1500)
    sleep    3
    WaitClickID    ${locator.tenderAdd}
    \    #
    Execute Javascript    window.scroll(1500,1500)
    ${items}=    Get From Dictionary    ${tender_data}    items
    Run Keyword If    '${TEST NAME}' == 'Можливість оголосити однопредметний тендер'    Додати предмет    ${items[0]}    0
    Run Keyword If    '${mode}' == 'Можливість оголосити багатопредметний тендер'    Додати багато предметів    ${items}
    #Run Keyword If    ${number_of_lots} > 0    Додати багато лотів    ${tender_data}
    \    #    #
    ${tender_UAid}=    Опублікувати тендер
    [Return]    ${tender_UAid}

Завантажити документ
    [Arguments]    ${username}    ${filepath}    ${tender_UAid}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tender_UAid}
    WaitClickID    ButtonTenderEdit
    Execute Javascript    window.scroll(1500,1500)
    WaitClickID    addFile
    Select From List By Label    id=category_of    Тендерна документація
    Select From List By Label    file_of    закупівлі
    WaitInputID    TenderFileUpload    ${filepath}
    WaitClickID    lnkDownload
    Wait Until Element Is Enabled    addFile
    WaitClickID    id=btnPublishTop

Завантажити документ в лот
    [Arguments]    ${username}    ${filepath}    ${TENDER_UAID}    ${lot_id}
    aps.Пошук тендера по ідентифікатору    ${username}    ${TENDER_UAID}
    Log To Console    ${filepath}
    Click Button    ButtonTenderEdit
    Click Element    addFile
    Select From List By Label    category_of    Документи закупівлі
    Select From List By Label    file_of    лоту
    Wait Until Element Is Enabled    id=FileComboSelection2
    Log To Console    ${lot_id}
    Run Keyword And Ignore Error    Select From List By Label    id=FileComboSelection2    ${lot_id}
    Choose File    id=TenderFileUpload    ${filepath}
    Click Link    id=lnkDownload
    Wait Until Element Is Enabled    addFile

Пошук тендера по ідентифікатору
    [Arguments]    ${username}    ${tender_UAid}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == tenderId
    Run Keyword If    '${TEST NAME}' == 'Можливість знайти однопредметний тендер по ідентифікатору'    Sleep    180
    Run Keyword If    '${username}' == 'aps_Viewer'    Go To    ${USERS.users['${username}'].homepage}/#testmodeOn    #SearchIdViewer    ${tender_UAid}    ${username}
    Run Keyword Unless    '${username}' == 'aps_Viewer'    Go To    ${USERS.users['${username}'].homepage}
    WaitInputXPATH    //input[@id='search_text']    ${tender_UAid}
    WaitClickID    search_btn
    Wait Until Page Contains Element    xpath=//div[@id="list_tenders"]//span[@id="ASPxLabel3"]    10
    WaitClickXPATH    (//div[@id="list_tenders"]//span[@id="ASPxLabel3"])[text()="${tender_UAid}"]/../../../../a/p    #(//p[@class='cut_title'])[last()]

Подати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == tenderId
    ...    ${ARGUMENTS[2]} == ${test_bid_data}
    Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    WaitClickID    ${locatorDeals}
    ${amount}=    Get From Dictionary    ${ARGUMENTS[2].data.value}    amount
    WaitInputID    editBid    ${amount}
    WaitClickID    addBidButton
    sleep    2
    ${resp}=    Get Value    id=my_bid_id
    [Return]    ${resp}

Додати предмет закупівлі
    [Arguments]    ${username}    ${tenderID}    ${item}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tenderID}
    WaitClickID    ButtonTenderEdit
    Додати предмет    ${item}    0
    WaitClickID    btnPublishTop

Видалити предмет закупівлі
    [Arguments]    ${username}    ${tenderID}    ${item_id}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tenderID}
    WaitClickID    ButtonTenderEdit
    sleep    5
    WaitClickXPATH    .//*[@id='NoLotsItemz']/div[${item_id}]
    sleep    5
    Click Element    xpath=//div[@class="col-sm-12 text-right"]/button[2]
    Wait Until Page Contains Element    id=AddItemButton    30
    Click Element    id=AddItemButton

Скасувати цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == none
    ...    ${ARGUMENTS[2]} == tenderId
    Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    WaitClickID    ${locatorDeals}
    sleep    2
    WaitClickID    btnDeleteBidspan
    Wait Until Page Contains Element    id=addBidButton

Login
    [Arguments]    @{ARGUMENTS}
    sleep    5
    Wait Until Element Is Visible    ${locatot.cabinetEnter}    10
    Click Element    ${locatot.cabinetEnter}
    Wait Until Element Is Visible    ${locator.emailField}    10
    Input Text    ${locator.emailField}    ${USERS.users['${ARGUMENTS[0]}'].login}
    Input Text    ${locator.passwordField}    ${USERS.users['${ARGUMENTS[0]}'].password}
    Click Element    ${locator.loginButton}

Оновити сторінку з тендером
    [Arguments]    @{ARGUMENTS}
    [Documentation]    [Documentation]
    ...    ... \ \ \ \ \ ${ARGUMENTS[0]} = \ username
    ...    ... \ \ \ \ \ ${ARGUMENTS[1]} = \ ${TENDER_UAID}
    Switch Browser    ${ARGUMENTS[0]}
    Reload Page

Задати питання
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == tenderUaId
    ...    ${ARGUMENTS[2]} == questionId
    ${title}=    Get From Dictionary    ${ARGUMENTS[2].data}    title
    ${description}=    Get From Dictionary    ${ARGUMENTS[2].data}    description
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    WaitClickXPATH    //a[@href="#questions"]
    WaitClickID    addQuestButton
    #Run Keyword And Ignore Error    Select From List By Label    лоту    # Вопрос к лоту с последующим выбором его
    #Run Keyword And Ignore Error    Select From List By Label    позиції    # Вопрос к позиции \ с последующим выбором ее
    #Run Keyword And Ignore Error    Select From List By Label    закупівлі    # Вопрос к закупке
    WaitInputID    editQuestionTitle    ${title}
    WaitInputID    editQuestionDetails    ${description}
    sleep    2
    WaitClickID    AddQuestion_Button
    Wait Until Page Contains    ${title}    30

Відповісти на питання
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} = username
    ...    ${ARGUMENTS[1]} = tenderUaId
    ...    ${ARGUMENTS[2]} = 0
    ...    ${ARGUMENTS[3]} = answer_data
    sleep    180
    ${answer}=    Get From Dictionary    ${ARGUMENTS[3].data}    answer
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    WaitClickXPATH    //a[@href="#questions"]
    WaitClickID    questionTitlespan1
    WaitClickID    answerQuestion
    WaitInputID    editAnswerDetails    ${answer}
    WaitClickID    AddQuestionButton
    Reload Page
    Wait Until Page Contains    ${answer}    30

Змінити цінову пропозицію
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == tenderId
    ...    ${ARGUMENTS[2]} == amount
    ...    ${ARGUMENTS[3]} == amount.value
    sleep    5
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    WaitClickID    ${locatorDeals}
    WaitClickID    btnDeleteBid
    WaitClickID    ${locatorDeals}
    sleep    3
    WaitInputID    editBid    ${ARGUMENTS[3]}
    sleep    3
    WaitClickID    addBidButton
    WaitClickID    ${locatorDeals}
    Wait Until Page Contains    Ви подали пропозицію. Очікуйте посилання на аукціон.

Внести зміни в тендер
    [Arguments]    @{ARGUMENTS}
    sleep    5
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    WaitClickID    ButtonTenderEdit
    Input text    id=edtTenderTitle    ${ARGUMENTS[2]}
    WaitClickID    btnPublishTop
    Wait Until Page Contains    ${ARGUMENTS[2]}    15
    WaitClickID    btnView

Завантажити документ в ставку
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[1]} == file
    ...    ${ARGUMENTS[2]} == tenderId
    sleep    5
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    Click Element    ${locatorDeals}
    Sleep    2
    Choose File    id=BidFileUpload    ${ARGUMENTS[1]}
    sleep    2
    Click Element    xpath=.//*[@id='lnkDownload'][@class="btn btn-success"]

Змінити документ в ставці
    [Arguments]    @{ARGUMENTS}
    [Documentation]    ${ARGUMENTS[0]} == username
    ...    ${ARGUMENTS[1]} == file
    ...    ${ARGUMENTS[2]} == tenderId
    Sleep    10
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    Reload Page
    WaitClickID    ${locatorDeals}
    WaitClickID    deleteBidFileButton
    WaitClickID    Button6
    WaitClickID    ${locatorDeals}
    Choose File    id=BidFileUpload    ${ARGUMENTS[1]}
    sleep    5
    WaitClickXPATH    .//*[@id='lnkDownload'][@class="btn btn-success"]

Отримати посилання на аукціон для глядача
    [Arguments]    @{ARGUMENTS}
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    Wait Until Page Contains    Аукціон    5
    ${url} =    Get Element Attribute    xpath=//a[@id="a_auction_url"]@href
    [Return]    ${url}

Отримати посилання на аукціон для учасника
    [Arguments]    @{ARGUMENTS}
    Selenium2Library.Switch Browser    ${ARGUMENTS[0]}
    aps.Пошук тендера по ідентифікатору    ${ARGUMENTS[0]}    ${ARGUMENTS[1]}
    Sleep    2
    ${url}=    Get Element Attribute    xpath=//a[@id="labelAuction2"]@href
    [Return]    ${url}

Отримати інформацію про status
    Reload Page
    Sleep    10
    Wait Until Page Contains Element    id=labelTenderStatus
    ${value}=    Get Text    id=labelTenderStatus
    Run Keyword If    '${TEST NAME}' == 'Можливість подати цінову пропозицію першим учасником'    Sleep    60
    Run Keyword And Return If    '${TEST NAME}' == 'Можливість подати цінову пропозицію першим учасником'    Active.tendering_provider    ${value}
    Run Keyword And Return If    '${TEST NAME}' == 'Можливість подати повторно цінову пропозицію першим учасником'    Active.tendering_provider    ${value}
    Run Keyword And Return If    '${TEST NAME}' == 'Можливість вичитати посилання на участь в аукціоні для першого учасника'    Active.auction_viewer    ${value}
    # Viewer
    Run Keyword And Return If    '${TEST NAME}' == 'Можливість вичитати посилання на аукціон для глядача'    Active.auction_viewer    ${value}
    [Return]    ${return_value}

Active.tendering_provider
    [Arguments]    ${value}
    Sleep    20
    ${return_value}=    Replace String    ${value}    Прийом пропозицій    active.tendering
    [Return]    ${return_value}

Active.auction_viewer
    [Arguments]    ${value}
    Sleep    60
    ${return_value}=    Replace String    ${value}    Аукціон    active.auction
    [Return]    ${return_value}

Створити лот
    [Arguments]    ${username}    ${tender_uaid}    ${lot}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tender_uaid}
    Click Button    ButtonTenderEdit
    Click Element    id=AddLot
    ${txt_title}=    Get From Dictionary    ${lot.data}    title
    Input Text    lot_name    ${txt_title}
    ${txt}=    Get From Dictionary    ${lot.data}    description
    Input Text    lot_description    ${txt}
    ${txt}=    Get From Dictionary    ${lot.data.value}    amount
    ${txt}=    Convert To String    ${txt}
    Input Text    lot_budget    ${txt}
    ${txt}=    Get From Dictionary    ${lot.data.minimalStep}    amount
    ${txt}=    Convert To String    ${txt}
    Input Text    lot_auction_min_step    ${txt}
    Click Element    id=button_add_lot

Видалити лот
    [Arguments]    ${username}    ${tender_uaid}    ${lot_id}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tender_uaid}
    Click Element    xpath=.//*[@id='headingThree']/h4/div[1]/div[2]/p/b[contains(text(), "${lot_id}")]
    sleep    2
    Click Element    xpath=.//div/div/div[2]/div[2]/a[contains(text(), 'Відміна')]
    sleep    3
    Input Text    id=reason_lot_cancel    Відміна лота
    Click Element    id=Button3

Змінити лот
    [Arguments]    ${username}    ${tender_uaid}    ${lot_id}    ${fieldname}    ${fieldvalue}
    Switch Browser    ${username}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tender_uaid}
    Click Button    ButtonTenderEdit
    sleep    2
    Execute Javascript    window.scroll(1500,1500)
    sleep    3
    Click Element    xpath=.//*[@id='headingThree']/h4/div[1]/div[2]/p/b[contains(text(), "${lot_id}")]
    Click Element    ${lot.btnEditEdt}
    Wait Until Element Is Visible    xpath=.//*[@id='button_delete_lot']
    Input Text    id=lot_description    ${fieldvalue}
    Click Element    id=button_add_lot

Додати предмет закупівлі в лот
    [Arguments]    ${username}    ${tender_uaid}    ${lot_id}    ${item}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tender_uaid}
    Click Button    ButtonTenderEdit
    Додати предмет    ${item}    0

Задати питання до лоту
    [Arguments]    ${username}    ${tender_uaid}    ${lot_id}    ${question}
    aps.Пошук тендера по ідентифікатору    ${username}    ${tender_uaid}
    sleep    3
    Wait Until Page Contains Element    xpath=//a[@href="#questions"]    20
    Click Element    xpath=//a[@href="#questions"]
    Wait Until Page Contains Element    id=addQuestButton    20
    Click Button    id=addQuestButton
    Select From List By Label    id=question_of    лоту
    Select From List By Label    id=FeatureComboSelection2    ${lot_id}
    Input text    id=editQuestionTitle    ${question.data.title}
    sleep    2
    Input text    id=editQuestionDetails    ${question.data.description}
    sleep    2
    Click Element    id=AddQuestion_Button
    Wait Until Page Contains    ${question.data.title}    30
    Capture Page Screenshot

Подати цінову пропозицію на лоти
    [Arguments]    ${username}    ${tender_uaid}    ${bid}    ${lots_ids}
    Switch Browser    ${username}
    aps.Пошук тендера по ідентифікатору    ${username} \    ${tender_uaid}
    Click Element    ${locatorDeals}
    Run Keyword And Ignore Error    Click Element    xpath=.//*[@id='divLotsPropositionsSwitch']/ul/li/a[contains(text(), "${lots_ids}")]
    Input Text    id=editBid    ${bid}
    Click Element    id=addBidButton

Отримати інформацію із лоту
    [Arguments]    ${username}    ${tender_uaid}    ${lot_id}    ${field_name}
    Switch Browser    ${username}
    Run Keyword If    '${field_name}' == 'lots.value.amount'    WaitClickXPATH    //div[@id="headingThree"]/h4/div/div/p/b[contains(text(), '${lot_id}')]
    sleep    5
    ${lot_value}=    Get Text    xpath=//div[@id="headingThree"]/h4/div/div/p/b[contains(text(), '${lot_id}')]/../../../..${locator.lots.${field_name}}
    ${lot_value}=    Convert To String    ${lot_value}
    Run Keyword And Return If    '${field_name}' == 'lots.value.amount'    lots.value.amount    ${lot_value}
    Run Keyword And Return If    '${field_name}' == 'lots.value.AddedTaxIncluded'    valueAddedTaxIncluded    ${lot_value}
    [Return]    ${lot_value}
