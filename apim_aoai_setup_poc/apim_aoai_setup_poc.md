## Overview
This repo will outline the steps to configure Azure API Management. This will allow enterprises to load balance their multiple Azure OpenAI endpoints. In addition to getting the API prompt text passed by users as well as other detailed metadata. Please note that to acquire the metadata, you will need to also configure Azure Log Analytics
<p></p>

### Steps:
### Step 1:
**Requirement!** All of your “deployment names” for each Azure Open AI endpoint for GPT need to be the same. This architecture will require you to create a new open AI service either in the same or multiple regions. Because each deployment name will require the same name for the round robin architecture to function correctly. 
<p></p>
Create an API Management service endpoint. Please ensure that you select the correct cipher, client-side protocols, and transport security that meets your business security requirements. For each Azure OpenAI endpoint, create “Backends” for URL. 

![image](https://github.com/Azure/aoai-apim/assets/91505344/9221ce58-72cc-49cb-a6c2-932f176b8530)

Ensure that you add the “openai” extension to each of your endpoints. 

![image](https://github.com/Azure/aoai-apim/assets/91505344/1536bfda-910b-4635-845b-bbce7ad20247)

In the headers, add “api-key” for the Azure OpenAI endpoint key. Please note that this can be also linked to Azure key vault, which we highly recommend. 

### Step 2:

Once each Azure OpenAI endpoint has been created in the “Backends”, proceed to create an API for Azure Open AI. You will be using the “HTTP” API. 

![image](https://github.com/Azure/aoai-apim/assets/91505344/38607693-30c6-4cb9-aaa0-81e7cfb9ccf5)

Select "Add API", the only values that are required are the “Display name” and “API URL suffix”. Please use “openai” as the API URL suffix. 

![image](https://github.com/Azure/aoai-apim/assets/91505344/46da1efe-1812-4c4f-8542-a9838efc2944)

Select “Add operation” and proceed to add a POST URL and all resources as “/*”.

![image](https://github.com/Azure/aoai-apim/assets/91505344/5341b041-2b11-4631-ab8f-b30d4a0b4458)

You can add GET request if required as well. Please confirm if your network and security team require both requests and if all resources are appropriate. 

### Step 3:

Select “All Operations” for the created API, then select “Policies” on the far right.  There are many policies that you can leverage to allow API to load balance as well as additional functionalities. The policy below uses two Azure OpenAI endpoints to load balance. Please note that the set parameter for engine to associate the endpoint to the specific endpoint is currently not functional. We instead used the same Azure Open AI deployment to get around this as outlined in step 1.  

![image](https://github.com/Azure/aoai-apim/assets/91505344/e55a0f3f-2cf4-4671-8850-cff706f08e91)

![image](https://github.com/Azure/aoai-apim/assets/91505344/5a97e2c2-da52-4193-9845-daa19137221b)

### Step 4:

Add the following policy to the window. Please note that you can add as many backend Azure Open AI endpoints as you have. You will need to append it to the “choose” condition. 


<pre> 
<policies>
    <inbound>
        <base />
        <set-header name="Content-Type" exists-action="override">
            <value>application/json</value>
        </set-header>
        <set-query-parameter name="api-version" exists-action="skip">
            <value>2023-03-15-preview</value>
        </set-query-parameter>
        <cache-lookup-value key="backend-counter" variable-name="backend-counter" />
        <choose>
            <when condition="@(!context.Variables.ContainsKey("backend-counter"))">
                <set-variable name="backend-counter" value="0" />
                <cache-store-value key="backend-counter" value="0" duration="100" />
            </when>
        </choose>
        <choose>
            <when condition="@(int.Parse((string)context.Variables["backend-counter"]) % 2 == 0)">
                <set-backend-service backend-id="<first_backend_policy_here>" />
                <set-variable name="backend-counter" value="1" />
                <cache-store-value key="backend-counter" value="1" duration="100" />
            </when>
            <otherwise>
                <set-backend-service backend-id="<second_backend_policy_here>" />
                <set-variable name="backend-counter" value="0" />
                <cache-store-value key="backend-counter" value="0" duration="100" />
            </otherwise>
        </choose>
    </inbound>
    <backend>
        <retry condition="@(context.Response.StatusCode >= 500 || context.Response.StatusCode >= 400)" count="12" interval="0" first-fast-retry="true">
            <choose>
                <when condition="@(context.Response.StatusCode >= 500 || context.Response.StatusCode >= 400)">
                    <choose>
                        <when condition="@(int.Parse((string)context.Variables["backend-counter"]) % 2 == 0)">
                            <set-backend-service backend-id="<first_backend_policy_here>" />
                            <set-variable name="backend-counter" value="1" />
                            <cache-store-value key="backend-counter" value="1" duration="100" />
                        </when>
                        <otherwise>
                            <set-backend-service backend-id="<second_backend_policy_here>" />
                            <set-variable name="backend-counter" value="0" />
                            <cache-store-value key="backend-counter" value="0" duration="100" />
                        </otherwise>
                    </choose>
                </when>
            </choose>
            <forward-request buffer-request-body="true" />
        </retry>
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
</pre>

### Step 5:

When testing your Azure Open AI chat completion, you will modify your method calls to the following: 
<pre>
openai.api_type = "azure"
openai.api_version = "2023-03-15-preview" 
openai.api_key = 'apim_key_here'
openai.api_base = 'https://apimendpointhere.azure-api.net'
openai.ChatCompletion.create(
    headers={"Ocp-Apim-Subscription-Key":'APIM_KEY_HERE'},
    engine="gpt-35-turbo", # engine = "deployment_name".
    messages=[{"role": "system", "content": f"""  You are an AI assistant that helps people find information."""},
        {"role": "user", "content": prompt}
    ],  
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        frequency_penalty=frequency_penalty,
        presence_penalty=presence_penalty,
        stop=stop
)
</pre>

Notice that we are specifying APIM key and endpoint for the api_key and api_base. Also notice that we are using an additional API header “Ocp-Apim-Subscription-Key” providing the APIM key once again. Most importantly, we are using the same engine name for each service or region deployment. 

<p></p>

#### Created by Victor Adeyanju CSA
