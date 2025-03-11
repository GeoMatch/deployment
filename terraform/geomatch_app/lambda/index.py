def lambda_handler(event, context):

   message = 'Hello {} !'.format(event['key1'])

   code = "world"
   message = 'Hello {} !'.format(code)
   return {
       'statusCode': 200,
       'body' : message
    }

