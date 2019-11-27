//Author: Wisner CELUCUS

public class UtilitiesRecordTrack
{
    public static Double getPercent( Integer numerateur, Integer denominateur )
    {
        return (Double) denominateur > 0 ? (((Double) numerateur / (Double) denominateur) * 100) : 0;
    }

    private static Map<String,Id> projectIdsByName
    {
        get
        {
            if ( projectIdsByName == null )
            {
                projectIdsByName = new Map<String,Id>();
                for ( Project_1__c project : [SELECT Id, Name FROM Project_1__c] )
                {
                    projectIdsByName.put( project.Name, project.Id );
                }
            }
            return projectIdsByName;
        }
        private set;
    }

    public static Id getProjectID( String projectName )
    {
        return projectIdsByName.get( projectName );
    }

    private static Map<String,List<Indicator_1__c>> indicatorsByNameAndProject
    {
        get
        {
            if ( indicatorsByNameAndProject == null )
            {
                indicatorsByNameAndProject = new Map<String,List<Indicator_1__c>>();
                for ( Indicator_1__c indicator :
                    [   SELECT  Id, Indicator_Full_Name__c, Related_Project__c
                        FROM Indicator_1__c
                    ]
                    )
                {
                    String combinedName = indicator.Indicator_Full_Name__c + '|' + indicator.Related_Project__c;
                    if ( !indicatorsByNameAndProject.containsKey( combinedName ) )
                    {
                        indicatorsByNameAndProject.put( combinedName, new List<Indicator_1__c>() );
                    }
                    indicatorsByNameAndProject.get( combinedName ).add( indicator );
                }
            }
            return indicatorsByNameAndProject;
        }
        private set;
    }

    public static List<Indicator_1__c> getIndicator( String indicatorFullName, String projectName )
    {
        String combinedName = indicatorFullName + '|' + getProjectID( projectName );
        List<Indicator_1__c> indicators = indicatorsByNameAndProject.get( combinedName ) ;
        return indicators != null ? indicators : new List<Indicator_1__c>();
    }

    private static Map<Decimal,Map<Id,Map<Id,List<Track_Indicator__c>>>> trackIndicatorsByMonth = new Map<Decimal,Map<Id,Map<Id,List<Track_Indicator__c>>>>();

    public static void prefetchTrackIndicators( Decimal month )
    {
        if ( trackIndicatorsByMonth.containsKey( month ) ) return;

        trackIndicatorsByMonth.put( month, new Map<Id,Map<Id,List<Track_Indicator__c>>>() );
        Map<Id,Map<Id,List<Track_Indicator__c>>> trackIndicatorsByIndicatorId = trackIndicatorsByMonth.get( month );

        for ( Track_Indicator__c trackIndicator :
            [   SELECT  Id, Indicator_Id__c, Operation_Name__c
                FROM    Track_Indicator__c
                WHERE   Month_Number__c = :month
            ]
            )
        {
            Id indicatorId = trackIndicator.Indicator_Id__c;
            Id operation = trackIndicator.Operation_Name__c;

            if ( !trackIndicatorsByIndicatorId.containsKey( indicatorId ) )
            {
                trackIndicatorsByIndicatorId.put( indicatorId, new Map<Id,List<Track_Indicator__c>>() );
            }
            Map<Id,List<Track_Indicator__c>> trackIndicatorsByOperation = trackIndicatorsByIndicatorId.get( indicatorId );

            if ( !trackIndicatorsByOperation.containsKey( operation ) )
            {
                trackIndicatorsByOperation.put( operation, new List<Track_Indicator__c>() );
            }
            List<Track_Indicator__c> trackIndicators = trackIndicatorsByOperation.get( operation );

            trackIndicators.add( trackIndicator );
        }
    }
}