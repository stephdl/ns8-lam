*** Settings ***
Library    SSHLibrary

*** Test Cases ***
Check if lam is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if lam can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"lam.test.local","http2https": true,"lets_encrypt": false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if lam works as expected
    ${output}  ${rc} =    Execute Command    sleep 10 && curl -H "Host: lam.test.local" -fkL https://127.0.0.1/
    ...    return_rc=True  return_stdout=True
    Should Be Equal As Integers    ${rc}  0

Check if lam is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
