*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of he robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Download the orders file
    ${orders_table}=    Get orders
    Loop the orders    ${orders_table}
    Zip receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser
    Go To    https://robotsparebinindustries.com/#/robot-order

Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    ${orders_table}=    Read table from CSV    orders.csv
    RETURN    ${orders_table}

Loop the orders
    [Arguments]    ${orders_table}
    FOR    ${order}    IN    @{orders_table}
        Fill the form    ${order}
        Submit Order    ${order}[Order number]
        Close the annoying modal
    END

Close the annoying modal
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${order_row}
    Click Element    id:head
    Select From List By Value    id:head    ${order_row}[Head]
    Click Element When Clickable
    ...    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(2) > div > div:nth-child(${order_row}[Body])
    Click Element When Clickable
    ...    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(2) > div > div:nth-child(${order_row}[Body])
    Click Element When Clickable
    ...    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(2) > div > div:nth-child(${order_row}[Body])

    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order_row}[Legs]
    Input Text    css:#address    ${order_row}[Address]

Preview Robot
    Click Button When Visible    id:preview

Submit Order
    [Arguments]    ${order_num}
    TRY
        Click Button When Visible    id:order
        ${pdf}=    Store the receipt as a PDF file    ${order_num}
        ${screenshot}=    Take a screenshot of the robot    ${order_num}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Remove File    ${screenshot}
        Click Button When Visible    id:order-another
    EXCEPT
        Submit Order    ${order_num}
    END

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${receipt_path}=    Set Variable    ${OUTPUT_DIR}${/}${order_num}.png
    Screenshot    id:receipt    ${receipt_path}
    ${files}=    Create List
    ...    ${receipt_path}
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}${order_num}.pdf
    Remove File    ${receipt_path}
    RETURN    ${OUTPUT_DIR}${/}${order_num}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_num}
    ${robot_screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}${order_num}_robot.png
    Screenshot    id:robot-preview-image    ${robot_screenshot_path}
    RETURN    ${robot_screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    ${True}
    Close All Pdfs

Zip receipts
    Create Directory    ${OUTPUT_DIR}/receipts
    ${files}=    Find Files    ${OUTPUT_DIR}/*.pdf
    Move Files    ${files}    ${OUTPUT_DIR}/receipts
    Archive Folder With Zip    ${OUTPUT_DIR}/receipts    receipts.zip
    Move File    receipts.zip    ${OUTPUT_DIR}/receipts.zip
    Remove Directory    ${OUTPUT_DIR}/receipts    True
