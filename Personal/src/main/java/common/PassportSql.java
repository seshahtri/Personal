package common;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

import config.Constants;

public class PassportSql {
	
	static Properties prop = new Properties();
	static FileInputStream fis;
	String databaseName;
	String client;
	
	public PassportSql() throws IOException {
		fis = new FileInputStream(Constants.config);
		prop.load(fis);
		this.databaseName = prop.getProperty("passportDatabaseName");
		//this.client = "('%" + prop.getProperty("client") + "\\_%')" + " ESCAPE '\\'";
		this.client = "('%" + prop.getProperty("client") + "%')";
	}
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @return
	 */
	public String getPassportSQL(String sqlLabel) {	
		if (getFormattedSQL(sqlLabel) != null) {
			return getFormattedSQL(sqlLabel);
		} else {
			return null;
		}
	}	
	

	/**
	 * 
	 * @param sqlLabel
	 * @return
	 */
	public String getFormattedSQL(String sqlLabel) {

		switch(sqlLabel) {
			case "getDashboardFromDb":  
				return  "SELECT D.display_name as DashboardName\r\n" + 
						"FROM [" + databaseName + "]..P_LA_DASHBOARD D\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_CLIENT_CATEGORY CC ON CC.ID = D.CLIENT_CATEGORY_ID\r\n" + 
						"WHERE CC.category LIKE" + client;

	
			case "getVizFromDb":				
			   	return	"SELECT Dv.display_name as VizName,\r\n" + 
			   			"D.display_name as DashboardName\r\n" + 
			   			"FROM [" + databaseName + "]..P_LA_DASHBOARD_DATA_VIZ  DDV\r\n" + 
			   			"LEFT JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV ON DDV.data_viz_id = DV.Id\r\n" + 
			   			"LEFT JOIN [" + databaseName + "]..P_LA_DASHBOARD D ON D.ID = DDV.DASHBOARD_ID\r\n" + 
			   			"JOIN [" + databaseName + "]..P_LA_CLIENT_CATEGORY CC ON CC.ID = DV.CLIENT_CATEGORY_ID\r\n" + 
			   			"WHERE CC.category LIKE" + client + "\r\n" + 
			   			"ORDER BY DashboardName asc";

			case "getDrillDownListFromDb":
				return "select DV.display_name as VizName,\r\n" + 
						" '['+ISNULL(dD.drilldownvizlist,'')+']' as DrillDownList\r\n" + 
						"from [" + databaseName + "]..P_LA_DATA_VIZ DV\r\n" + 
						"LEFT JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV1 ON DV1.ID = DV.tabular_data_viz_id\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_CLIENT_CATEGORY CC ON CC.ID = DV.CLIENT_CATEGORY_ID\r\n" + 
						"LEFT JOIN [" + databaseName + "]..P_LA_DETAILS_PAGE_LAYOUT L ON L.ID = DV.tabular_view_layout_id\r\n" + 
						"LEFT JOIN (select distinct ActualViz,\r\n" + 
						"STUFF((Select ',''' + display_name + ''''\r\n" + 
						"from (SELECT DV.name as ActualViz ,DV2.name as DrilldownViz, dv2.display_name FROM\r\n" + 
						" [" + databaseName + "]..P_LA_DATA_VIZ_DR_DOWN_LIST DDL\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV ON DDL.la_data_viz_id = DV.ID\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV2  ON DDL.drill_down_list_id = DV2.ID) T1\r\n" + 
						"where T1.ActualViz=T2.ActualViz\r\n" + 
						"FOR XML PATH('')),1,1,'') AS drilldownvizlist from (SELECT distinct DV.name as ActualViz, DV2.name as DrilldownViz, dv2.display_name FROM\r\n" + 
						" [" + databaseName + "]..P_LA_DATA_VIZ_DR_DOWN_LIST DDL\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV ON DDL.la_data_viz_id = DV.ID\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV2  ON DDL.drill_down_list_id = DV2.ID) T2) dd on dd.ActualViz = DV.name\r\n" + 
						"WHERE CC.category LIKE" + client + "\r\n" + 
						"order by vizName asc";

			case "getDrillParamFromDb":		
			   	return	"select dv.display_name as VizName,\r\n" + 
			   			"DVOP.source_field as sourceField\r\n" + 
			   			"from [" + databaseName + "]..P_LA_DATAVIZ_OUT_PARAMETER DVOP\r\n" + 
			   			"LEFT JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV ON DVOP.data_viz_id = DV.Id\r\n" + 
			   			"JOIN [" + databaseName + "]..P_LA_PARAMETER P ON p.id = DVOP.out_parameter_id\r\n" + 
			   			"JOIN [" + databaseName + "]..P_LA_CLIENT_CATEGORY CC ON CC.ID = DV.CLIENT_CATEGORY_ID\r\n" + 
			   			"WHERE CC.category LIKE" + client;	
				   	
			case "getDefaultFiltersFromDb":
				return "SELECT GF.display_name as displayName,\r\n" + 
						"FDT.display_name as displayType,\r\n" + 
						"F.name as filter,\r\n" + 
						"CASE WHEN GF.is_currency_filter = 1 THEN 'TRUE' ELSE 'FALSE' END AS [isCurrencyFilter],\r\n" + 
						"CASE WHEN GF.is_primary = 1 THEN 'TRUE' ELSE 'FALSE' END AS [isPrimary],\r\n" + 
						"CASE WHEN GF.is_searchable = 1 THEN 'TRUE' ELSE 'FALSE' END AS [isSearchble],\r\n" + 
						"GF.order_sequence as orderSequence,\r\n" + 
						"GF.original_entity_id as originalEntityId,\r\n" + 
						"GF.version,\r\n" + 
						"GF.version_status as versionStaus\r\n" + 
						"FROM [" + databaseName + "]..P_LA_GLOBAL_FILTER GF\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_FILTER_DISPLAY_TYPE FDT ON FDT.id = GF.display_type_id\r\n" + 
						"JOIN [" + databaseName + "]..P_LA_FILTER F on F.id = GF.filter_id\r\n" + 
						"WHERE GF.name LIKE" + client;		
				
			case "getVizDescription":
				return "SELECT D.display_name as Dashboard,\r\n" + 
						"Dv.display_name as VizName,\r\n" + 
						"DV.description as Description\r\n" + 
						"FROM [" + databaseName + "]..P_LA_DASHBOARD_DATA_VIZ  DDV\r\n" + 
						"LEFT JOIN [" + databaseName + "]..P_LA_DATA_VIZ DV ON DDV.data_viz_id = DV.Id\r\n" + 
						"LEFT JOIN [" + databaseName + "]..P_LA_DASHBOARD D ON D.ID = DDV.DASHBOARD_ID\r\n" + 
						"JOIN ["  + databaseName + "]..P_LA_CLIENT_CATEGORY CC ON CC.ID = DV.CLIENT_CATEGORY_ID\r\n" + 
						"WHERE CC.category LIKE" + client + "\r\n" + 
						"ORDER BY Dashboard asc";
				}
		return null;
	}
}
