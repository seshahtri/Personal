package common;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

import config.Constants;

public class Database extends Base{	
	
	PassportSql pass;
	Report report;
	
	public Database() throws IOException {
		this.pass = new PassportSql();
		this.report = new Report();
	}	
	

	/**
	 * 
	 * @param sqlLabel
	 * @return
	 * @throws IOException 
	 */
	public ArrayList<String> getDataFromPassportDb(String sqlLabel) throws IOException {
		
		ArrayList<String> data = new ArrayList<String>();
		ArrayList<String> result = new ArrayList<String>();
		Vector<String> columnNames = new Vector<String>();

		try {	
			data = passportDbCreds();			
			Statement stmt = null;
		    ResultSet rs = null;
		    Connection conn = null;
    
			conn = DriverManager.getConnection(data.get(0) + Base.getStringConfigData("passportDatabaseName"), data.get(1), data.get(2));			
			stmt = conn.createStatement();
		    rs = stmt.executeQuery(pass.getPassportSQL(sqlLabel));
		    
		    if (rs != null) {
		        ResultSetMetaData rsmd = rs.getMetaData();	        
		        String temp = "";
		        for (int i = 1; i <= rsmd.getColumnCount(); i++) {
		          columnNames.add(rsmd.getColumnName(i));
		        	if (i <= (rsmd.getColumnCount() - 1)) {
			        	temp += rsmd.getColumnName(i) + "|";
		        	} else {
			        	temp += rsmd.getColumnName(i);
		        	}
		        }
		        
		        result.add(temp);
		        
		        while (rs.next()) {
			        temp = "";
		        	for (int k = 0; k < columnNames.size(); k++) {
		        		if (k < (columnNames.size() - 1)) {
				        	temp += rs.getString(columnNames.get(k)) + "|";
			        	} else {
				        	temp += rs.getString(columnNames.get(k));
			        	}
	    	        }
			        result.add(temp);
		        }
		      }	    	
	        conn.close();
		} catch (SQLException e) {
			report.log("Message", "There is an error, while connecting database.... (" + e.getMessage() + ")");
			return null;
		} catch (IOException e) {
			report.log("Message", "IOException occured (" + e.getMessage() + ")");
			return null;
		}
		return result;
	}		
	

	/**
	 * 
	 * @param sql
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> getDataFromClientDb(String sql) throws IOException {
		
		ArrayList<String> data = new ArrayList<String>();
		ArrayList<String> result = new ArrayList<String>();
		Vector<String> columnNames = new Vector<String>();

		try {	
			data = clientDbCreds();
			
			Statement stmt = null;
		    ResultSet rs = null;
		    Connection conn = null;
    
			conn = DriverManager.getConnection(data.get(0) + Base.getStringConfigData("clientDatabaseName"), data.get(1), data.get(2));	
			stmt = conn.createStatement();	
			rs = stmt.executeQuery(getFormattedSQL(sql, null));
			
		    if (rs != null) {
		        ResultSetMetaData rsmd = rs.getMetaData();	        
		        String temp = "";
		        for (int i = 1; i <= rsmd.getColumnCount(); i++) {
		          columnNames.add(rsmd.getColumnName(i));
		        	if (i <= (rsmd.getColumnCount() - 1)) {
			        	temp += rsmd.getColumnName(i) + "|";
		        	} else {
			        	temp += rsmd.getColumnName(i);
		        	}
		        }
		        
		        result.add(temp);
		        
		        while (rs.next()) {
			        temp = "";
		        	for (int k = 0; k < columnNames.size(); k++) {
		        		String tempData = "";
		        		if (k < (columnNames.size() - 1)) {
		        			tempData = rs.getString(columnNames.get(k));
		        			if(tempData != null) {
				    			while(tempData.indexOf("|") >= 0) {
				    				tempData = tempData.replace("|", ""); 
			    				}
		        			}
				        	temp += tempData + "|";
			        	} else {
		        			tempData = rs.getString(columnNames.get(k));
		        			if(tempData != null) {
				    			while(tempData.indexOf("|") >= 0) {
				    				tempData = tempData.replace("|", ""); 
			    				}
		        			}
				        	temp += tempData;
			        	}
	    	        }
			        result.add(temp);
		        }
		      }	    	
	        conn.close();
		} catch (SQLException e) {
			report.error("Message", "There is an error, while connecting database.... (" + e.getMessage() + ")");
			return null;
		} catch (IOException e) {
			report.error("Message", "IOException occured (" + e.getMessage() + ")");
			return null;
		}
		return result;
	}	

	
	/**
	 * 
	 * @param params
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> getDataFromClientDb(ArrayList<String> params) throws IOException {
		
		ArrayList<String> data = new ArrayList<String>();
		ArrayList<String> result = new ArrayList<String>();
		Vector<String> columnNames = new Vector<String>();

		try {	
			data = clientDbCreds();
			
			PreparedStatement stmt = null;
		    ResultSet rs = null;
		    Connection conn = null;	    
		    String sql = getSQL(params.get(0));
		    
		    if (sql != null) {		    	
			
				conn = DriverManager.getConnection(data.get(0) + Base.getStringConfigData("clientDatabaseName"), data.get(1), data.get(2));
				stmt = conn.prepareStatement(getFormattedSQL(sql, params));			
	            rs = stmt.executeQuery();
            
			    if (rs != null) {
			        ResultSetMetaData rsmd = rs.getMetaData();	        
			        String temp = "";
			        for (int i = 1; i <= rsmd.getColumnCount(); i++) {
			          columnNames.add(rsmd.getColumnName(i));
			        	if (i <= (rsmd.getColumnCount() - 1)) {
				        	temp += rsmd.getColumnName(i) + "|";
			        	} else {
				        	temp += rsmd.getColumnName(i);
			        	}
			        }
			        
			        result.add(temp);
			        
			        while (rs.next()) {
				        temp = "";
			        	for (int k = 0; k < columnNames.size(); k++) {
			        		String tempData = "";
			        		if (k < (columnNames.size() - 1)) {
			        			tempData = rs.getString(columnNames.get(k));
			        			if(tempData != null) {
					    			while(tempData.indexOf("|") >= 0) {
					    				tempData = tempData.replace("|", ""); 
				    				}
			        			}
					        	temp += tempData + "|";
				        	} else {
			        			tempData = rs.getString(columnNames.get(k));
			        			if(tempData != null) {
					    			while(tempData.indexOf("|") >= 0) {
					    				tempData = tempData.replace("|", ""); 
				    				}
			        			}
					        	temp += tempData;
				        	}
		    	        }
				        result.add(temp);
			        }
			      }	    	
		        conn.close();
		    } else {
				report.warning("Message", params.get(0) + " SQL not exists in the sql database");
		    }
		} catch (SQLException e) {
			report.error("Message", "There is an error, while connecting database.... (" + e.getMessage() + ")");
			return null;
		} catch (IOException e) {
			report.error("Message", "IOException occured (" + e.getMessage() + ")");
			return null;
		}
		return result;
	}		
	
	
	/**
	 * 
	 * @param sql
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> getColumnDataTypeFromClientDb(String sql) throws IOException {
		
		ArrayList<String> result = new ArrayList<String>();
		ArrayList<String> data = new ArrayList<String>();
		try {	
			data = clientDbCreds();
			
			Statement stmt = null;
		    ResultSet rs = null;
		    Connection conn = null;
    
			conn = DriverManager.getConnection(data.get(0) + Base.getStringConfigData("clientDatabaseName"), data.get(1), data.get(2));			
			stmt = conn.createStatement();
			rs = stmt.executeQuery(getFormattedSQL(sql, null));

		    if (rs != null) {
		        ResultSetMetaData rsmd = rs.getMetaData();	
		        for (int i = 1; i <= rsmd.getColumnCount(); i++) {
		        	result.add(rsmd.getColumnName(i) + ":" + rsmd.getColumnTypeName(i));
		        }                
		     }	    	
	        conn.close();
		} catch (SQLException e) {
			report.error("Message", "There is an error, while connecting database.... (" + e.getMessage() + ")");
			return null;
		} catch (IOException e) {
			report.error("Message", "IOException occured (" + e.getMessage() + ")");
			return null;
		}
		return result;
	}		

	
	/**
	 * 
	 * @param params
	 * @return
	 * @throws IOException
	 */
	public ArrayList<String> getColumnDataTypeFromClientDb(ArrayList<String> params) throws IOException {
		
		ArrayList<String> result = new ArrayList<String>();
		ArrayList<String> data = new ArrayList<String>();
		try {	
			data = clientDbCreds();		
			
			Statement stmt = null;
		    ResultSet rs = null;
		    Connection conn = null;
		    String sql = getSQL(params.get(0));
		    
		    if (sql != null) {		    	
		    	
				conn = DriverManager.getConnection(data.get(0) + Base.getStringConfigData("clientDatabaseName"), data.get(1), data.get(2));	
				stmt = conn.createStatement();
				rs = stmt.executeQuery(getFormattedSQL(sql, params));

			    if (rs != null) {
			        ResultSetMetaData rsmd = rs.getMetaData();	
			        for (int i = 1; i <= rsmd.getColumnCount(); i++) {
			        	result.add(rsmd.getColumnName(i) + ":" + rsmd.getColumnTypeName(i));
			        }                
			    }	    	
		        conn.close();				
		    } else {
				report.warning("Message", params.get(0) + " SQL not exists in the sql database");
		    }	    
		} catch (SQLException e) {
			report.error("Message", "There is an error, while connecting database.... (" + e.getMessage() + ")");
			return null;
		} catch (IOException e) {
			report.error("Message", "IOException occured (" + e.getMessage() + ")");
			return null;
		}
		return result;
	}	
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @return
	 * @throws IOException 
	 */
	public int getColumnCountFromDb(String sqlLabel) throws IOException {
		
		ArrayList<String> data = new ArrayList<String>();
		int count = 0;

		try {
			data = passportDbCreds();
			Statement stmt = null;
		    ResultSet rs = null;
		    Connection conn = null;		    	
    
			conn = DriverManager.getConnection(data.get(0) + Base.getStringConfigData("passportDatabaseName"), data.get(1), data.get(2));			
		
			stmt = conn.createStatement();
		    rs = stmt.executeQuery(pass.getPassportSQL(sqlLabel));
		    
		    if (rs != null) {
		        ResultSetMetaData rsmd = rs.getMetaData();	        
		        count = rsmd.getColumnCount();
		    }	    	
	        conn.close();
		} catch (SQLException e) {
			report.log("Message", "There is an error, while connecting database.... (" + e.getMessage() + ")");
			return 0;
		} catch (IOException e) {
			report.log("Message", "IOException occured (" + e.getMessage() + ")");
			return 0;
		}
		return count;
	}		
	
	
	/**
	 * 
	 * @param dashboardName
	 * @param vizName
	 * @return
	 * @throws IOException 
	 */
	public boolean verifyDashVizExistsInDb(String dashboardName, String vizName) throws IOException {
		ArrayList<String> data = new ArrayList<String>();
		int columnCount = getColumnCountFromDb("getVizFromDb");		
		if (columnCount != 0) {
			data = getDataFromPassportDb("getVizFromDb");
			if (data != null) {
				if (columnCount == 1) {
					for(int i = 0; i < data.size(); i++) {
						if (data.get(i).equalsIgnoreCase(dashboardName)) {
							return true;
						}
					}
				} 
				else if(columnCount > 1) {
					for (int i = 0; i < data.size(); i++) {
						String[] temp = data.get(i).split("\\|");
						if ((temp[0].equalsIgnoreCase(vizName)) && (temp[1].equalsIgnoreCase(dashboardName))) {
							return true;
						}
					}
				}
				return false;
			} else return false;
		} else return false;
	}	
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws IOException 
	 */
	public String getDrillDownParamKeyFromDb(String vizName) throws IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromPassportDb("getDrillParamFromDb");
		for (int i = 0; i < data.size(); i++) {
			String[] temp = data.get(i).split("\\|");
			if ((temp[0].equalsIgnoreCase(vizName))){
				return temp[1];
			}
		}
		return null;
	}	
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public String getDrillDownParamValueDataTypeFromDb(String sqlLabel) throws SQLException, IOException {
		return getColumnDataTypeFromClientDb(getSQL(sqlLabel)).get(0).split(":")[1].trim();
	}	
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public long getDrillDownParamValueIntIdFromDb(String sqlLabel) throws SQLException, IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromClientDb(getSQL(sqlLabel));
		for (int i = 1; i < data.size();) {
			String[] temp = data.get(i).split("\\|");
			return Long.valueOf(temp[0]);
		}
		return 0;
	}	
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public String getDrillDownParamValueStringIdFromDb(String sqlLabel) throws SQLException, IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromClientDb(getSQL(sqlLabel));
		for (int i = 1; i < data.size();) {
			String[] temp = data.get(i).split("\\|");
			return temp[0];
		}
		return null;
	}	
	
	
	/**
	 * 
	 * @param params
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public String getDrillDownParamValueDataTypeFromDb(ArrayList<String> params) throws SQLException, IOException {
		return getColumnDataTypeFromClientDb(params).get(0).split(":")[1].trim();
	}	
	
	
	/**
	 * 
	 * @param params
	 * @return
	 * @throws IOException
	 */
	public long getDrillDownParamValueIntIdFromDb(ArrayList<String> params) throws IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromClientDb(params);
		for (int i = 1; i < data.size();) {
			String[] temp = data.get(i).split("\\|");
			return Long.valueOf(temp[0]);
		}
		return 0;
	}	
	
	
	/**
	 * 
	 * @param params
	 * @return
	 * @throws IOException
	 */
	public String getDrillDownParamValueStringIdFromDb(ArrayList<String> params) throws IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromClientDb(params);
		for (int i = 1; i < data.size();) {
			String[] temp = data.get(i).split("\\|");
			return temp[0];
		}
		return null;
	}	
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public String getDrillDownParamValueNameFromDb(String sqlLabel) throws SQLException, IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromClientDb(getSQL(sqlLabel));
		for (int i = 1; i < data.size();) {
			String[] temp = data.get(i).split("\\|");
			return temp[1];
		}
		return null;
	}		
	
	
	/**
	 * 
	 * @param params
	 * @return
	 * @throws IOException
	 */
	public String getDrillDownParamValueNameFromDb(ArrayList<String> params) throws IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromClientDb(params);
		for (int i = 1; i < data.size();) {
			String[] temp = data.get(i).split("\\|");
			return temp[1];
		}
		return null;
	}	
	
	
	/**
	 * 
	 * @param vizName
	 * @return
	 * @throws IOException 
	 */
	public ArrayList<String> getDrillDownListFromDb(String vizName) throws IOException {
		ArrayList<String> data = new ArrayList<String>();	
		ArrayList<String> tempList = new ArrayList<String>();
		String[] temp;
		String[] tempOne;
		data = getDataFromPassportDb("getDrillDownListFromDb");
		for (int i = 0; i < data.size(); i++) {
			temp = data.get(i).split("\\|");
			if ((temp[0].equalsIgnoreCase(vizName))){
				if (temp[1].length() <= 2) {
					return null;
				}
				else if ((temp[1].length() > 2) && (temp[1].contains(","))) {									
					tempOne = temp[1].split("\\,");
					for (int j = 0; j < tempOne.length; j++) {
						if (j == 0) {
							tempList.add((tempOne[j].substring(2, tempOne[j].length()-1)).trim());
						}
						else if (j == tempOne.length - 1) {
							tempList.add((tempOne[j].substring(1, tempOne[j].length()-2)).trim());
						}
						else {
							tempList.add((tempOne[j].substring(1, tempOne[j].length()-1)).trim());	
						}						
					}
				}
				else {
					tempList.add((temp[1].substring(2, temp[1].length()-2)).trim());
				}
				return tempList;
			}
		}
		return null;
	}	
	
	
	/**
	 * 
	 * @param sqlLabel
	 * @param params
	 * @return
	 */	
	public ArrayList<String> createArrayList(String sqlLabel, ArrayList<String> params) {

		ArrayList<String> temp =  new ArrayList<String>();
		temp.add(sqlLabel);
		for (int i = 0; i < params.size(); i++) {
			temp.add(params.get(i));
		}		
		return temp;		
	}		
	
		
	/**
	 * 
	 * @param key
	 * @param value
	 * @param dataType
	 * @return
	 */
	public String addToArrayList(String key, String value, String dataType) {
		return key + "|" + value + "|" + dataType;
	}		
	
	
	/**
	 * 
	 * @param inputString
	 * @return
	 * @throws SQLException 
	 * @throws IOException 
	 */
	public String getSQL(String inputString) throws SQLException, IOException {		

		String folderName = getClientPath(Constants.sqlPath + Base.getStringRunTimeData("test") + "\\");
		if (folderName != null) {		
			String line, sql = "", sqlPath = null;
			ArrayList<String> data = new ArrayList<String>();
			data = executeSQL(inputString);
			boolean execute = Boolean.parseBoolean(data.get(0));
			String[] tempString = inputString.split("_");	
	
			try {
				if (execute) {				
					if (Base.getStringRunTimeData("test").equals("regression")) {
						sqlPath = Constants.sqlPath + Base.getStringRunTimeData("test") + "\\" + folderName + "\\" + tempString[0].toLowerCase() + "\\" + tempString[2] + "\\" + tempString[3] + "\\" + tempString[1] + "\\" + data.get(1);
					}
					if (Base.getStringRunTimeData("test").equals("filters")) {
						sqlPath = Constants.sqlPath + Base.getStringRunTimeData("test") + "\\" + folderName + "\\" + tempString[0].toLowerCase() + "\\" + tempString[2] + "\\" + tempString[1] + "\\" + data.get(1);
					}
					BufferedReader br = new BufferedReader(new FileReader(sqlPath));
					while ((line = br.readLine()) != null) {sql += "\n" + line;}
					br.close();
				}
			} catch (FileNotFoundException e) {
				return null;
			}
			return sql;
		}
		else {
			return null;
		}
	}	
	
	
	/**
	 * 
	 * @return
	 * @throws IOException
	 */
	public String getClientPath(String folderPath) throws IOException {
		File directoryPath = new File(folderPath);
		String contents[] = directoryPath.list();
		for(int i=0; i<contents.length; i++) {
			if ( Base.getStringConfigData("client").contains(contents[i])) {
				//System.out.println(contents[i]);
				return contents[i];
			}
		}
		return null;
	}
	

	/**
	 * parentDirName
	 * @param inputString
	 * @return
	 * @throws SQLException 
	 * @throws IOException 
	 */
	public ArrayList<String> executeSQL(String inputString) throws SQLException, IOException {		
		
		String folderName = getClientPath(Constants.sqlPath + Base.getStringRunTimeData("test") + "\\");
		
		ArrayList<String> data = new ArrayList<String>();
		String fileName = null, sqlPath = null, vizLevel = null, sqlParamType = "NA";
		boolean execute = false, isNoOrFalseExists = false;
		String[] tempString = inputString.split("_");	
		
		switch(tempString[1]) {
		case "BaseLevel":
			vizLevel = tempString[3];
			break;
		case "FirstLevel":
			vizLevel = tempString[4];
			break;
		case "SecondLevel":
			vizLevel = tempString[4] + "_" + tempString[5];
			break;
		}
		
		if (Base.getStringRunTimeData("test").equals("regression")) {
			sqlPath = Constants.sqlPath + Base.getStringRunTimeData("test") + "\\" + folderName + "\\" + tempString[0].toLowerCase() + "\\" + tempString[2] + "\\" + tempString[3] + "\\" + tempString[1] + "\\";
		}
		if (Base.getStringRunTimeData("test").equals("filters")) {
			sqlPath = Constants.sqlPath + Base.getStringRunTimeData("test") + "\\" + folderName + "\\" + tempString[0].toLowerCase() + "\\" + tempString[2] + "\\" + tempString[1] + "\\";
		}

		File folder = new File(sqlPath);
		File[] listOfFiles = folder.listFiles();
		
		if (listOfFiles != null) {
			if (tempString[1].equals("BaseLevel") || tempString[1].equals("FirstLevel")) {			
				for (int i=0; i<listOfFiles.length; i++) {
					fileName = listOfFiles[i].getName();					
					if (fileName.indexOf("_") != -1) {
						if (fileName.contains(vizLevel)) {
							String[] temp = fileName.split("\\.");
							String tmpStr = "";
							for (int a=0; a<temp.length; a++ ) {
								if (!temp[a].equalsIgnoreCase("sql")) {
									tmpStr += temp[a];
								}
							}
							if (tmpStr.indexOf("_") != -1) {
								String[] tempOne = tmpStr.split("_");
								for (int j=0; j<tempOne.length; j++) {
									if (tempOne[j].equalsIgnoreCase("no") || tempOne[j].equalsIgnoreCase("false")) {
										isNoOrFalseExists = true;
										execute = false;
										break;
									}
								}
							}
							if (!isNoOrFalseExists) {
								execute = true;
							}					
							break;
						}
					} 
					else {
						String[] temp = fileName.split("\\.");
						String tmpStr = "";
						for (int a=0; a<temp.length; a++ ) {
							if (!temp[a].equalsIgnoreCase("sql")) {
								tmpStr += temp[a]+ ".";
							}
						}
						
						if (tmpStr.substring(0, tmpStr.length()-1).equalsIgnoreCase(vizLevel)) {
							execute = true;
							break;
						}

					}
				}
			}
			
			if (tempString[1].equals("SecondLevel")) {
				for (int i=0; i<listOfFiles.length; i++) {
					fileName = listOfFiles[i].getName();
					if (fileName.contains(vizLevel)) {
						String[] temp = fileName.split("\\.");
						String tmpStr = "";
						for (int a=0; a<temp.length; a++ ) {
							if (!temp[a].equalsIgnoreCase("sql")) {
								tmpStr += temp[a];
							}
						}
						String[] tempOne = tmpStr.split("_");
						for (int j=0; j<tempOne.length; j++) {
							if (tempOne[j].equalsIgnoreCase("no") || tempOne[j].equalsIgnoreCase("false")) {
								isNoOrFalseExists = true;
								execute = false;
								break;
							}
						}
						if (!isNoOrFalseExists) {
							execute = true;
						}					
						break;
					}
				}
			}
		} else {
			report.warning("Message", tempString[0] + " sql not exists in the folder for client (" +  Base.getStringConfigData("client") + ")");
		}
		data.add(Boolean.toString(execute));
		data.add(fileName);
		data.add(sqlParamType);
		return data;
	}
	
	
	/**
	 * 
	 * @param dashboardName
	 * @param vizName
	 * @return
	 * @throws IOException 
	 */
	public String verifyVizDescriptionInDb(String dashboardName, String vizName) throws IOException {
		ArrayList<String> data = new ArrayList<String>();
		data = getDataFromPassportDb("getVizDescription");
		for (int i = 0; i < data.size(); i++) {
			String[] temp = data.get(i).split("\\|");
			if ((temp[0].equalsIgnoreCase(dashboardName)) && (temp[1].equalsIgnoreCase(vizName))){
				return temp[2];
			}
		}
		return null;
	}	
	
	
	/**
	 * 
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public Map<String, String> getFormatedSaveFilterData() throws SQLException, IOException {
		Map<String, String> newMap = new HashMap<String, String>();
		switch(getStringConfigData("client")){
			case "C00348":					
				newMap.put("DateRange",getStringFilterData("C00348-DateRange").replace(" ", ""));
				newMap.put("StartDate",getStringFilterData("C00348-StartDate").replace(" ", ""));
				newMap.put("EndDate",getStringFilterData("C00348-EndDate").replace(" ", ""));
				newMap.put("Currency",getStringFilterData("C00348-Currency").replace(" ", ""));
				newMap.put("InvoiceOptions",getStringFilterData("C00348-InvoiceStatus").replace(" ", ""));
				newMap.put("ClientLevel",getStringFilterData("C00348-ClientLevel").replace(" ", ""));
				newMap.put("GBLocation",getStringFilterData("C00348-GBLocation").replace(" ", ""));
				newMap.put("InvoiceDateField",getStringFilterData("C00348-InvoiceDate").replace(" ", ""));
				newMap.put("Matter",getStringFilterData("C00348-MatterStatus").replace(" ", ""));
				newMap.put("MatterName",getStringFilterData("C00348-MatterName").replace(" ", ""));
				newMap.put("MatterOwner",getStringFilterData("C00348-MatterOwner").replace(" ", ""));
				newMap.put("Vendor",getStringFilterData("C00348-VendorName").replace(" ", ""));
				newMap.put("VendorType",getStringFilterData("C00348-VendorType").replace(" ", ""));
				newMap.put("Country",getStringFilterData("C00348-DFCountry").replace(" ", ""));
				newMap.put("CoverageGroup",getStringFilterData("C00348-DFCoverageGroup").replace(" ", ""));
				newMap.put("CoverageType",getStringFilterData("C00348-DFCoverageType").replace(" ", ""));
				newMap.put("BenefitState",getStringFilterData("C00348-DFBenefitState").replace(" ", ""));
				newMap.put("AccidentState",getStringFilterData("C00348-DFAccidentState").replace(" ", ""));
				newMap.put("StatusCode",getStringFilterData("C00348-DFStatusCode").replace(" ", ""));
				newMap.put("ClaimNumber",getStringFilterData("C00348-DFClaimNumber").replace(" ", ""));
				newMap.put("GBBranchName",getStringFilterData("C00348-DFGBBranchName").replace(" ", ""));
				newMap.put("GBBranchNumber",getStringFilterData("C00348-DFGBBranchNumber").replace(" ", ""));
				return newMap;
				
			case "DEV044":					
				newMap.put("DateRange",getStringFilterData("DEV044-DateRange").replace(" ", ""));
				newMap.put("StartDate",getStringFilterData("DEV044-StartDate").replace(" ", ""));
				newMap.put("EndDate",getStringFilterData("DEV044-EndDate").replace(" ", ""));
				newMap.put("Currency",getStringFilterData("DEV044-Currency").replace(" ", ""));
				newMap.put("InvoiceOptions",getStringFilterData("DEV044-InvoiceStatus").replace(" ", ""));
				newMap.put("PracticeArea",getStringFilterData("DEV044-PracticeArea").replace(" ", ""));
				newMap.put("BusinessUnit",getStringFilterData("DEV044-BusinessUnit").replace(" ", ""));
				newMap.put("InvoiceDateField",getStringFilterData("DEV044-InvoiceDate").replace(" ", ""));
				newMap.put("MatterStatus",getStringFilterData("DEV044-MatterStatus").replace(" ", ""));
				newMap.put("Matter",getStringFilterData("DEV044-MatterName").replace(" ", ""));
				newMap.put("MatterNumber",getStringFilterData("DEV044-MatterNumber").replace(" ", ""));
				newMap.put("MatterOwner",getStringFilterData("DEV044-MatterOwner").replace(" ", ""));
				newMap.put("Vendor",getStringFilterData("DEV044-VendorName").replace(" ", ""));
				newMap.put("VendorType",getStringFilterData("DEV044-VendorType").replace(" ", ""));
				newMap.put("MatterDynamicField1",getStringFilterData("DEV044-DFMatterDynamicField1").replace(" ", ""));
				newMap.put("MatterDynamicField2",getStringFilterData("DEV044-DFMatterDynamicField2").replace(" ", ""));
				newMap.put("MatterVendorDynamicField1",getStringFilterData("DEV044-DFMatterVendorDynamicField1").replace(" ", ""));
				newMap.put("MatterVendorDynamicField2",getStringFilterData("DEV044-DFMatterVendorDynamicField2").replace(" ", ""));
				return newMap;

		}
		return null;
	}	


	/**
	 * 
	 * @param sql
	 * @param params
	 * @return
	 * @throws SQLException
	 * @throws IOException
	 */
	public String getFormattedSQL(String sql, ArrayList<String> params) throws SQLException, IOException {
		
		String ParamOne = null, ParamOneDataType = null, ParamTwo = null, ParamTwoDataType = null;
		
		if (params != null) {
			if (params.size()==2) {
				ParamOne = params.get(1).split("\\|")[1];
				ParamOneDataType = params.get(1).split("\\|")[2];
			}
			if (params.size()==3) {
				ParamOne = params.get(1).split("\\|")[1];
				ParamOneDataType = params.get(1).split("\\|")[2];
				ParamTwo = params.get(2).split("\\|")[1];
				ParamTwoDataType = params.get(2).split("\\|")[2];
			}
		}
		
		String[] temp = sql.split("\\^");
		String formattedSql = "";
		
		switch(getStringRunTimeData("test")) {
		
			case "filters":					
				switch(getStringConfigData("client")) {
				
					case "C00348":
						for(int i=0; i<temp.length; i++) {
							if (temp[i].trim().equalsIgnoreCase("ParamOne")) {
								if (ParamOneDataType.equalsIgnoreCase("int")) {
									temp[i] = ParamOne;
								} else {
									temp[i] = "'" + ParamOne + "'";					
								}
							}
							if (temp[i].trim().equalsIgnoreCase("ParamTwo")) {
								if (ParamTwoDataType.equalsIgnoreCase("int")) {
									temp[i] = ParamTwo;
								} else {
									temp[i] = "'" + ParamTwo + "'";					
								}
							}
							if (temp[i].trim().equalsIgnoreCase("StartDate")) {
								temp[i] = "'" + getStringFilterData("C00348-StartDate") + "'";
							}
							if (temp[i].trim().equalsIgnoreCase("EndDate")) {
								temp[i] = "'" + getStringFilterData("C00348-EndDate") + "'";
							}
							if (temp[i].trim().equalsIgnoreCase("Currency")) {
								temp[i] = "'" + getStringFilterData("C00348-Currency") + "'";
							}
							if (temp[i].trim().equalsIgnoreCase("InvoiceStatus")) {
								String[] iop = getStringFilterData("C00348-InvoiceStatus").split(";");
								if (iop.length == 1) temp[i] = "'" + getStringFilterData("C00348-InvoiceStatus") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<iop.length; j++) {
										tmpStr += "'" + iop[j].trim() + "'" + "','";
										if (j == iop.length-1) tmpStr += "'" + iop[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}	
							if (temp[i].trim().equalsIgnoreCase("InvoiceDate")) {
								temp[i] =  "'" + getStringFilterData("C00348-InvoiceDate").replaceAll("\\ ", "") + "'";				
							}			
							if (temp[i].trim().equalsIgnoreCase("ClientLevel")) {
								String[] cl = getStringFilterData("C00348-ClientLevel").split(";");
								if (cl.length == 1) temp[i] = "'" + getStringFilterData("C00348-ClientLevel") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<cl.length; j++) {
										tmpStr += "'" + cl[j].trim() + "'" + ",";
										if (j == cl.length-1) tmpStr += "'" + cl[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("GBLocation")) {
								String[] loc = getStringFilterData("C00348-GBLocation").split(";");
								if (loc.length == 1) temp[i] = "'" + getStringFilterData("C00348-GBLocation") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<loc.length; j++) {
										tmpStr += "'" + loc[j].trim() + "'" + ",";
										if (j == loc.length-1) tmpStr += "'" + loc[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("MatterStatus")) {
								String[] ms = getStringFilterData("C00348-MatterStatus").split(";");
								if (ms.length == 1) temp[i] = "'" + getStringFilterData("C00348-MatterStatus") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<ms.length; j++) {
										tmpStr += "'" + ms[j].trim() + "'" + ",";
										if (j == ms.length-1) tmpStr += "'" + ms[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("MatterName")) {
								String[] mn = getStringFilterData("C00348-MatterName").split(";");
								if (mn.length == 1) temp[i] = "'" + getStringFilterData("C00348-MatterName") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<mn.length; j++) {
										tmpStr += "'" + mn[j].trim() + "'" + ",";
										if (j == mn.length-1) tmpStr += "'" + mn[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("MatterOwner")) {
								String[] mo = getStringFilterData("C00348-MatterOwner").split(";");
								if (mo.length == 1) temp[i] = "'" + getStringFilterData("C00348-MatterOwner") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<mo.length; j++) {
										tmpStr += "'" + mo[j].trim() + "'" + ",";
										if (j == mo.length-1) tmpStr += "'" + mo[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}
							if (temp[i].trim().equalsIgnoreCase("VendorName")) {
								String[] vm = getStringFilterData("C00348-VendorName").split(";");
								if (vm.length == 1) temp[i] = "'" + getStringFilterData("C00348-VendorName") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<vm.length; j++) {
										tmpStr += "'" + vm[j].trim() + "'" + ",";
										if (j == vm.length-1) tmpStr += "'" + vm[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("VendorType")) {
								String[] vt = getStringFilterData("C00348-VendorType").split(";");
								if (vt.length == 1) temp[i] = "'" + getStringFilterData("C00348-VendorType") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<vt.length; j++) {
										tmpStr += "'" + vt[j].trim() + "'" + ",";
										if (j == vt.length-1) tmpStr += "'" + vt[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFCountry")) {
								String[] dfc = getStringFilterData("C00348-DFCountry").split(";");
								if (dfc.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFCountry") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfc.length; j++) {
										tmpStr += "'" + dfc[j].trim() + "'" + ",";
										if (j == dfc.length-1) tmpStr += "'" + dfc[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFCoverageGroup")) {
								String[] dfcg = getStringFilterData("C00348-DFCoverageGroup").split(";");
								if (dfcg.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFCoverageGroup") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfcg.length; j++) {
										tmpStr += "'" + dfcg[j].trim() + "'" + ",";
										if (j == dfcg.length-1) tmpStr += "'" + dfcg[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFCoverageType")) {
								String[] dfct = getStringFilterData("C00348-DFCoverageType").split(";");
								if (dfct.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFCoverageType") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfct.length; j++) {
										tmpStr += "'" + dfct[j].trim() + "'" + ",";
										if (j == dfct.length-1) tmpStr += "'" + dfct[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFBenefitState")) {
								String[] dfbs = getStringFilterData("C00348-DFBenefitState").split(";");
								if (dfbs.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFBenefitState") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfbs.length; j++) {
										tmpStr += "'" + dfbs[j].trim() + "'" + ",";
										if (j == dfbs.length-1) tmpStr += "'" + dfbs[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFAccidentState")) {
								String[] dfas = getStringFilterData("C00348-DFAccidentState").split(";");
								if (dfas.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFAccidentState") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfas.length; j++) {
										tmpStr += "'" + dfas[j].trim() + "'" + ",";
										if (j == dfas.length-1) tmpStr += "'" + dfas[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFStatusCode")) {
								String[] dfsc = getStringFilterData("C00348-DFStatusCode").split(";");
								if (dfsc.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFStatusCode") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfsc.length; j++) {
										tmpStr += "'" + dfsc[j].trim() + "'" + ",";
										if (j == dfsc.length-1) tmpStr += "'" + dfsc[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFClaimNumber")) {
								String[] dfcn = getStringFilterData("C00348-DFClaimNumber").split(";");
								if (dfcn.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFClaimNumber") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfcn.length; j++) {
										tmpStr += "'" + dfcn[j].trim() + "'" + ",";
										if (j == dfcn.length-1) tmpStr += "'" + dfcn[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFGBBranchName")) {
								String[] dfbn = getStringFilterData("C00348-DFGBBranchName").split(";");
								if (dfbn.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFGBBranchName") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfbn.length; j++) {
										tmpStr += "'" + dfbn[j].trim() + "'" + ",";
										if (j == dfbn.length-1) tmpStr += "'" + dfbn[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFGBBranchNumber")) {
								String[] dfbno = getStringFilterData("C00348-DFGBBranchNumber").split(";");
								if (dfbno.length == 1) temp[i] = "'" + getStringFilterData("C00348-DFGBBranchNumber") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfbno.length; j++) {
										tmpStr += "'" + dfbno[j].trim() + "'" + ",";
										if (j == dfbno.length-1) tmpStr += "'" + dfbno[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							formattedSql += temp[i];
						}		
						
						
					case "DEV044":
						for(int i=0; i<temp.length; i++) {
							if (temp[i].trim().equalsIgnoreCase("ParamOne")) {
								if (ParamOneDataType.equalsIgnoreCase("int")) {
									temp[i] = ParamOne;
								} else {
									temp[i] = "'" + ParamOne + "'";					
								}
							}
							if (temp[i].trim().equalsIgnoreCase("ParamTwo")) {
								if (ParamTwoDataType.equalsIgnoreCase("int")) {
									temp[i] = ParamTwo;
								} else {
									temp[i] = "'" + ParamTwo + "'";					
								}
							}
							if (temp[i].trim().equalsIgnoreCase("StartDate")) {
								temp[i] = "'" + getStringFilterData("DEV044-StartDate") + "'";
							}
							if (temp[i].trim().equalsIgnoreCase("EndDate")) {
								temp[i] = "'" + getStringFilterData("DEV044-EndDate") + "'";
							}
							if (temp[i].trim().equalsIgnoreCase("Currency")) {
								temp[i] = "'" + getStringFilterData("DEV044-Currency") + "'";
							}
							if (temp[i].trim().equalsIgnoreCase("InvoiceStatus")) {
								String[] iop = getStringFilterData("DEV044-InvoiceStatus").split(";");
								if (iop.length == 1) temp[i] = "'" + getStringFilterData("DEV044-InvoiceStatus") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<iop.length; j++) {
										tmpStr += "'" + iop[j].trim() + "'" + "','";
										if (j == iop.length-1) tmpStr += "'" + iop[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}	
							if (temp[i].trim().equalsIgnoreCase("InvoiceDate")) {
								temp[i] =  "'" + getStringFilterData("DEV044-InvoiceDate").replaceAll("\\ ", "") + "'";				
							}	
							if (temp[i].trim().equalsIgnoreCase("MatterName")) {
								String[] mn = getStringFilterData("DEV044-MatterName").split(";");
								if (mn.length == 1) temp[i] = "'" + getStringFilterData("DEV044-MatterName") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<mn.length; j++) {
										tmpStr += "'" + mn[j].trim() + "'" + ",";
										if (j == mn.length-1) tmpStr += "'" + mn[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}
							if (temp[i].trim().equalsIgnoreCase("MatterNumber")) {
								String[] mn = getStringFilterData("DEV044-MatterNumber").split(";");
								if (mn.length == 1) temp[i] = "'" + getStringFilterData("DEV044-MatterNumber") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<mn.length; j++) {
										tmpStr += "'" + mn[j].trim() + "'" + ",";
										if (j == mn.length-1) tmpStr += "'" + mn[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}
							if (temp[i].trim().equalsIgnoreCase("MatterStatus")) {
								String[] ms = getStringFilterData("DEV044-MatterStatus").split(";");
								if (ms.length == 1) temp[i] = "'" + getStringFilterData("DEV044-MatterStatus") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<ms.length; j++) {
										tmpStr += "'" + ms[j].trim() + "'" + ",";
										if (j == ms.length-1) tmpStr += "'" + ms[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("MatterOwner")) {
								String[] mo = getStringFilterData("DEV044-MatterOwner").split(";");
								if (mo.length == 1) temp[i] = "'" + getStringFilterData("DEV044-MatterOwner") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<mo.length; j++) {
										tmpStr += "'" + mo[j].trim() + "'" + ",";
										if (j == mo.length-1) tmpStr += "'" + mo[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}
							if (temp[i].trim().equalsIgnoreCase("VendorName")) {
								String[] vm = getStringFilterData("DEV044-VendorName").split(";");
								if (vm.length == 1) temp[i] = "'" + getStringFilterData("DEV044-VendorName") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<vm.length; j++) {
										tmpStr += "'" + vm[j].trim() + "'" + ",";
										if (j == vm.length-1) tmpStr += "'" + vm[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("VendorType")) {
								String[] vt = getStringFilterData("DEV044-VendorType").split(";");
								if (vt.length == 1) temp[i] = "'" + getStringFilterData("DEV044-VendorType") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<vt.length; j++) {
										tmpStr += "'" + vt[j].trim() + "'" + ",";
										if (j == vt.length-1) tmpStr += "'" + vt[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("PracticeArea")) {
								String[] pa = getStringFilterData("DEV044-PracticeArea").split(";");
								if (pa.length == 1) temp[i] = "'" + getStringFilterData("DEV044-PracticeArea") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<pa.length; j++) {
										tmpStr += "'" + pa[j].trim() + "'" + ",";
										if (j == pa.length-1) tmpStr += "'" + pa[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("BusinessUnit")) {
								String[] bu = getStringFilterData("DEV044-BusinessUnit").split(";");
								if (bu.length == 1) temp[i] = "'" + getStringFilterData("DEV044-BusinessUnit") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<bu.length; j++) {
										tmpStr += "'" + bu[j].trim() + "'" + ",";
										if (j == bu.length-1) tmpStr += "'" + bu[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFMatterDynamicField1")) {
								String[] dfc = getStringFilterData("DEV044-DFMatterDynamicField1").split(";");
								if (dfc.length == 1) temp[i] = "'" + getStringFilterData("DEV044-DFMatterDynamicField1") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfc.length; j++) {
										tmpStr += "'" + dfc[j].trim() + "'" + ",";
										if (j == dfc.length-1) tmpStr += "'" + dfc[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFMatterDynamicField2")) {
								String[] dfcg = getStringFilterData("DEV044-DFMatterDynamicField2").split(";");
								if (dfcg.length == 1) temp[i] = "'" + getStringFilterData("DEV044-DFMatterDynamicField2") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfcg.length; j++) {
										tmpStr += "'" + dfcg[j].trim() + "'" + ",";
										if (j == dfcg.length-1) tmpStr += "'" + dfcg[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFMatterVendorDynamicField1")) {
								String[] dfct = getStringFilterData("DEV044-DFMatterVendorDynamicField1").split(";");
								if (dfct.length == 1) temp[i] = "'" + getStringFilterData("DEV044-DFMatterVendorDynamicField1") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfct.length; j++) {
										tmpStr += "'" + dfct[j].trim() + "'" + ",";
										if (j == dfct.length-1) tmpStr += "'" + dfct[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							if (temp[i].trim().equalsIgnoreCase("DFMatterVendorDynamicField2")) {
								String[] dfbs = getStringFilterData("DEV044-DFMatterVendorDynamicField2").split(";");
								if (dfbs.length == 1) temp[i] = "'" + getStringFilterData("DEV044-DFMatterVendorDynamicField2") + "'";
								else {
									String tmpStr = "";
									for(int j=0; j<dfbs.length; j++) {
										tmpStr += "'" + dfbs[j].trim() + "'" + ",";
										if (j == dfbs.length-1) tmpStr += "'" + dfbs[j].trim() + "'";
									}
									temp[i] = tmpStr;				
								}
							}			
							formattedSql += temp[i];
						}					
						
						return formattedSql;
				}
				
			case "regression":			
				for(int i=0; i<temp.length; i++) {
					if (temp[i].trim().equalsIgnoreCase("ParamOne")) {
						if (ParamOneDataType.equalsIgnoreCase("int")) {
							temp[i] = ParamOne;
						} else {
							temp[i] = "''" + ParamOne + "''";					
						}
					}
					if (temp[i].trim().equalsIgnoreCase("ParamTwo")) {
						if (ParamTwoDataType.equalsIgnoreCase("int")) {
							temp[i] = ParamTwo;
						} else {
							temp[i] = "''" + ParamTwo + "''";					
						}
					}
					if (temp[i].trim().equalsIgnoreCase("StartDate")) {
						temp[i] = "'" + getStringFilterData("DEFAULT-StartDate") + "'";
					}
					if (temp[i].trim().equalsIgnoreCase("EndDate")) {
						temp[i] = "'" + getStringFilterData("DEFAULT-EndDate") + "'";
					}
					if (temp[i].trim().equalsIgnoreCase("Currency")) {
						temp[i] = "'" + getStringFilterData("DEFAULT-Currency") + "'";
					}
					if (temp[i].trim().equalsIgnoreCase("InvoiceStatus")) {
						String[] iop = getStringFilterData("DEFAULT-InvoiceStatus").split(";");
						if (iop.length == 1) temp[i] = "'" + getStringFilterData("DEFAULT-InvoiceStatus") + "'";
						else {
							String tmpStr = "";
							for(int j=0; j<iop.length; j++) {
								tmpStr += "'" + iop[j].trim() + "'" + "','";
								if (j == iop.length-1) tmpStr += "'" + iop[j].trim() + "'";
							}
							temp[i] = tmpStr;				
						}
					}
					if (temp[i].trim().equalsIgnoreCase("ReviewStatus")) {
						String[] rs = getStringFilterData("DEFAULT-ReviewStatus").split(";");
						if (rs.length == 1) temp[i] = "'" + getStringFilterData("DEFAULT-ReviewStatus") + "'";
						else {
							String tmpStr = "";
							for(int j=0; j<rs.length; j++) {
								tmpStr += "'" + rs[j].trim() + "'" + "','";
								if (j == rs.length-1) tmpStr += "'" + rs[j].trim() + "'";
							}
							temp[i] = tmpStr;				
						}
					}	

					formattedSql += temp[i];
				}	
				return formattedSql;

			default:
				return sql;
		}
	}
	
}
