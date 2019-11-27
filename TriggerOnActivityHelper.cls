//Author: Wisner CELUCUS

public class RecordTrackOnActivityHelperRefactored
{
    private static Map<Decimal,Map<String,Map<Id,Map<Id,AggregateResult>>>> resultsByMonth = new Map<Decimal,Map<String,Map<Id,Map<Id,AggregateResult>>>>();

    public static void prefetchResults( Decimal month )
    {
        if ( resultsByMonth.containsKey( month ) ) return;

        resultsByMonth.put( month, new Map<String,Map<Id,Map<Id,AggregateResult>>>() );
        Map<String,Map<Id,Map<Id,AggregateResult>>> resultsByActivityType = resultsByMonth.get( month );

        for ( AggregateResult result :
            [   SELECT  COUNT(Id) numRecords,
                        SUM(Number_Of_Participant__c) numParticipants,
                        SUM(Number_Of_Male_Participant__c) numMales,
                        SUM(Number_Of_Female_Participant__c) numFemales,
                        Activity_Type__c, Project_Name__c, Operation_Name__c
                FROM    Activity_1__c
                WHERE   Month_Number__c = :month
                GROUP BY Activity_Type__c, Project_Name__c, Operation_Name__c
            ]
            )
        {
            String activityType = (String) result.get( 'Activity_Type__c' );
            Id projectId = (Id) result.get( 'Project_Name__c' );
            Id operation = (Id) result.get( 'Operation_Name__c' );

            if ( !resultsByActivityType.containsKey( activityType ) )
            {
                resultsByActivityType.put( activityType, new Map<Id,Map<Id,AggregateResult>>() );
            }
            Map<Id,Map<Id,AggregateResult>> resultsByProjectId = resultsByActivityType.get( activityType );

            if ( !resultsByProjectId.containsKey( projectId ) )
            {
                resultsByProjectId.put( projectId, new Map<Id,AggregateResult>() );
            }
            Map<Id,AggregateResult> resultsByOperation = resultsByProjectId.get( projectId );

            resultsByOperation.put( operation, result );
        }
    }

    private static Double getResult( Decimal month, Id operation, String activityType, Id projectId, String alias )
    {
        prefetchResults( month );

        Map<String,Map<Id,Map<Id,AggregateResult>>> resultsByActivityType = resultsByMonth.get( month );
        if ( resultsByActivityType == null ) return 0;

        Map<Id,Map<Id,AggregateResult>> resultsByProjectId = resultsByActivityType.get( activityType );
        if ( resultsByProjectId == null ) return 0;

        Map<Id,AggregateResult> resultsByOperation = resultsByProjectId.get( projectId );
        if ( resultsByOperation == null ) return 0;

        AggregateResult result = resultsByOperation.get( operation );
        if ( result == null ) return 0;

        return Double.valueOf( result.get( alias ) );
    }

    public static Double getTotalActivityOn( Decimal month, Id operation, String activityType, Id projectId )
    {
        return getResult( month, operation, activityType, projectId, 'numRecords' );
    }

    public static Double getTotalCommunityMemberSensitized( Decimal month, Id operation, String activityType, Id projectId )
    {
        return getResult( month, operation, activityType, projectId, 'numParticipants' );
    }

    public static Double getTotalTotalConertHeledBy( Decimal month, Id operation, String activityType, Id projectId )
    {
        return getResult( month, operation, activityType, projectId, 'numRecords' );
    }

    public static Double getTotalBoys( Decimal month, Id operation, String activityType, Id projectId )
    {
        return getResult( month, operation, activityType, projectId, 'numMales' );
    }

    public static Double getTotalGirls( Decimal month, Id operation, String activityType, Id projectId )
    {
        return getResult( month, operation, activityType, projectId, 'numFemales' );
    }

    private static Map<String,String> activityTypesByIndicator = new Map<String,String>
    {   
        'WASH|# of hygiene club meeting carried out'        => 'hygiene club meeting carried out -(WASH)'
    ,   'WASH|# of sensitization campaigns carried out'     => 'sensitization campaigns'
    ,   'WASH|# of Delmas 32 community members sensitized on WASH issues'        => 'sensitization campaigns'
    ,   'WASH|# of parent meetings held on WASH issues'     => 'Meeting With Parent'
     
   };

    public static void recordTrack( List<Activity_1__c> newRecords, String indicatorFullName, String projectName )
    {
        String activityType = activityTypesByIndicator.get( projectName + '|' + indicatorFullName );
        if ( activityType == null ) return;

        List<Indicator_1__c> indicator = UtilitiesRecordTrack.getIndicator( indicatorFullName , projectName );
        if ( indicator.isEmpty() ) return;

        List<Track_Indicator__c> trackIndicatorsToUpsert = new List<Track_Indicator__c>();
        
        Map<String, Decimal> allDifferentMonths = new Map<String, Decimal>();
        String combinedOpAndMonth = '';
        
        for ( Activity_1__c act : newRecords )
        {
            
            if  (   act.Activity_Type__c != activityType
                ||  act.Project_Name__c != UtilitiesRecordTrack.getProjectID( projectName )
                ) continue;
             combinedOpAndMonth = act.Operation_Name__c + '-' + act.Month_Number__c;
           if(!allDifferentMonths.containsKey( combinedOpAndMonth ))
           {
            if(
                  indicatorFullName == 'community activity conducted by adolescents'
               || indicatorFullName == '# of community activities conducted by kids'
               || indicatorFullName == '# of training session conducted for volunteers'
               || indicatorFullName == '# of concerts held by Little Kids Band with special guest musicians'
               || indicatorFullName == '# of concerts held by Little Kids Band'
               || indicatorFullName == '# of parent meetings held on WASH issues'
               || indicatorFullName == '# of sensitization campaigns carried out'
               || indicatorFullName == '# of hygiene club meeting carried out'
               || indicatorFullName == 'Number of  training sessions held'
               || indicatorFullName == 'Number of meetings with parents'
               || indicatorFullName == 'Number  extracurricular activities'
              
              
              
              
              ){
				Decimal actual = (Decimal) getTotalActivityOn( act.Month_Number__c, act.Operation_Name__c, act.Activity_Type__c, indicator[0].Related_Project__c );
            	Track_Indicator__c[] tracked =  UtilitiesRecordTrack.getTrackIndicatorId( indicator[0].Id, act.Month_Number__c, act.Operation_Name__c );
            	trackIndicatorsToUpsert.add( UtilitiesRecordTrack.recordOrUpdate( tracked, actual, act.End_At__c.date(), indicator[0].Id, act.Operation_Name__c ) );   
            }
            
            if(
                   indicatorFullName == '# of Delmas 32 community members sensitized on WASH issues'
                || indicatorFullName == '# of people sensitized on the importance of after-school activities'
            )
            {
				Decimal actual = (Decimal) getTotalCommunityMemberSensitized( act.Month_Number__c, act.Operation_Name__c, act.Activity_Type__c, indicator[0].Related_Project__c );
            	Track_Indicator__c[] tracked =  UtilitiesRecordTrack.getTrackIndicatorId( indicator[0].Id, act.Month_Number__c, act.Operation_Name__c );
            	trackIndicatorsToUpsert.add( UtilitiesRecordTrack.recordOrUpdate( tracked, actual, act.End_At__c.date(), indicator[0].Id, act.Operation_Name__c ) );   
            }
            if(
                   indicatorFullName == '# of boys participating in after-school activities'
                || indicatorFullName == 'of boys reading at the library'
                || indicatorFullName == '# of male adolescents attending training on sexual health and risk behavior linked to their age'
            )
            {
				Decimal actual = (Decimal) getTotalBoys( act.Month_Number__c, act.Operation_Name__c, act.Activity_Type__c, indicator[0].Related_Project__c );
            	Track_Indicator__c[] tracked =  UtilitiesRecordTrack.getTrackIndicatorId( indicator[0].Id, act.Month_Number__c, act.Operation_Name__c );
            	trackIndicatorsToUpsert.add( UtilitiesRecordTrack.recordOrUpdate( tracked, actual, act.End_At__c.date(), indicator[0].Id, act.Operation_Name__c ) );   
            }
            if(
                   indicatorFullName == '# of girls participating in after-school activities'
                || indicatorFullName == '# of girls reading at the library'
                || indicatorFullName == '# of female adolescents attending training on sexual health and risks behavior linked to their age'
            )
            {
				Decimal actual = (Decimal) getTotalGirls( act.Month_Number__c, act.Operation_Name__c, act.Activity_Type__c, indicator[0].Related_Project__c );
            	Track_Indicator__c[] tracked =  UtilitiesRecordTrack.getTrackIndicatorId( indicator[0].Id, act.Month_Number__c, act.Operation_Name__c );
            	trackIndicatorsToUpsert.add( UtilitiesRecordTrack.recordOrUpdate( tracked, actual, act.End_At__c.date(), indicator[0].Id, act.Operation_Name__c ) );   
            }
            if(!allDifferentMonths.containsKey( combinedOpAndMonth )) allDifferentMonths.put( combinedOpAndMonth , act.Month_Number__c);
               
           }

        }
        upsert trackIndicatorsToUpsert;
    }
}