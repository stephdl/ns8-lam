*** Settings ***
Documentation    LAM needs a user domain to manage, so the suite brings up an
...              OpenLDAP provider first, the way the ns8-sogo suite does.
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${CLUSTER_USER}     admin
${CLUSTER_PASSWORD}    Nethesis,1234
${USER_DOMAIN}      ldap.dom.test
${TEST_HOST}        lam.ns8-ci.test
${ADMIN_USER}       u1

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${CLUSTER_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${CLUSTER_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Fetch page
    [Documentation]    Fetch a page through Traefik, following redirects
    [Arguments]    ${path}
    ${output}  ${rc} =    Execute Command
    ...    curl -fkL -H "Host: ${TEST_HOST}" https://127.0.0.1${path}
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    RETURN    ${output}

*** Test Cases ***
Check if the account provider is installed
    ${response} =    Run task    add-internal-provider    {"image":"openldap","node":1}
    Set Suite Variable    ${ldap_id}    ${response['module_id']}
    Run task    module/${ldap_id}/configure-module
    ...    {"domain":"${USER_DOMAIN}","admuser":"admin","admpass":"Nethesis,1234","provision":"new-domain"}
    Run task    module/${ldap_id}/add-user
    ...    {"user":"${ADMIN_USER}","display_name":"LAM Administrator","password":"Nethesis,1234"}

Check if lam is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if lam can be configured
    Run task    module/${module_id}/configure-module
    ...    {"host":"${TEST_HOST}","http2https":true,"lets_encrypt":false,"ldap_domain":"${USER_DOMAIN}","ldap_admin_users":"${ADMIN_USER}"}
    ...    decode_json=${FALSE}

Check if lam configuration reads back
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${config}[host]    ${TEST_HOST}
    Should Be Equal    ${config}[ldap_domain]    ${USER_DOMAIN}

Check if the lam login page is served through Traefik
    ${page} =    Wait Until Keyword Succeeds    60s    5s    Fetch page    /
    # LAM titles every page, and the form asks for the profile to manage
    Should Contain    ${page}    LDAP Account Manager

Take screenshots of the module pages
    [Documentation]    Capture what cluster-admin shows, for the software center
    ...                entry. Tagged ui: the shared runner skips it unless
    ...                RUN_UI_TESTS is true, since it needs a browser.
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True    viewport={'width': 1280, 'height': 900}
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    # The page fills itself from several tasks: let them land
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=about
    Wait For Elements State    iframe >>> h2 >> text="About"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/3._About.png
    Close Browser

Check if lam is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if the user domain is removed correctly
    Run task    remove-internal-domain    {"domain":"${USER_DOMAIN}"}
