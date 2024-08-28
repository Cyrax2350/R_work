#portfolio_cadastral 
#--------------------------------------------------------------------------------
# Project geometry processing
#--------------------------------------------------------------------------------
# SETUP
#--------------------------------------------------------------------------------
# set working directory
setwd("/Users/silas.darnell/Dropbox (GreenCollar)/R Apps Development/R Apps Research/Silas/Spatial_projects")

#--------------------------------------------------------------------------------
Sys.setenv(TZ='Australia/Sydney')
# get current date
current_date=Sys.Date()
current_datetime=Sys.time()
#--------------------------------------------------------------------------------
#install.packages("geojson")
library(dplyr) 
library(lubridate) 
library(sf) 
library(RMariaDB)
library(mapboxapi) 
library(geojson)
library(ggplot2)
sf_use_s2(TRUE)
message(sf_use_s2())
sessionInfo()
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
settingsfile = '~/Documents/silas.cnf' 

all_projectDb <- dbConnect(RMariaDB::MariaDB(), default.file = settingsfile, group="mysql-prod", dbname = 'erf_project')  
dbListTables(all_projectDb)


dbListTables(all_projectDb) 

querya="SELECT g.project_id,p.project_name,p.portfolio,ST_AsText(g.cadastral_boundary) As geometry,ST_SRID(g.cadastral_boundary) AS geometry_epsg, AsWKT(ST_Centroid(g.cadastral_boundary)) as centroid
FROM erf_project.project_geometry g
right JOIN erf_project.all_project p
ON p.project_id = g.project_id
WHERE p.project_id NOT IN(606600,616700,618205)
and g.cadastral_boundary is not null;"

print(querya)
a = dbSendQuery(all_projectDb,querya)
project_geometry = dbFetch(a)
print(a)

dbClearResult(a)

dbDisconnect(all_projectDb)
#--------------------------------------------------------------------------------
# Inputs processing
#--------------------------------------------------------------------------------
# cadastral boundaries processing
#--------------------------------------------------------------------------------
sfc= st_sfc()
files.project = c(project_geometry$project_id)
project_geometry_simp = project_geometry
start.loop = Sys.time()

for (f.project in files.project){
  
  message(f.project)
  pos.project = which(project_geometry$project_id==f.project)
  project_name = project_geometry$project_name[pos.project]
  project_id = as.integer(project_geometry$project_id[pos.project])
  portfolio = as.character(project_geometry$portfolio[pos.project])
  
  boundary_in = st_as_sfc(project_geometry$geometry[pos.project])
  st_crs(boundary_in) = project_geometry$geometry_epsg[pos.project]
  
  boundary_in_GDA94 = st_transform(boundary_in,4283)
  boundary_in_GDA94 = st_make_valid(boundary_in_GDA94)
  
  boundary_in_GDA94 = st_sfc(boundary_in_GDA94)
  boundary_in_GDA94 = st_sf(data.frame(geom=boundary_in_GDA94,project_id, project_name, portfolio))
  
  length(sfc)
  if((length(sfc))==0){sfc=boundary_in_GDA94} else
  {sfc = do.call(rbind, list(sfc, boundary_in_GDA94))}
  
}

end.loop = Sys.time()
message("inputs processing (cadastral boundaries) duration: ", difftime(end.loop,start.loop, units = "mins")," minutes")

if(file.exists('output/nat_all_projects.geojson')) {file.remove('output/nat_all_projects.geojson')}
st_write(sfc, "output/nat_all_projects.geojson")

if(file.exists('output/nat_all_projects.kml')) {file.remove('output/nat_all_projects.kml')}
st_write(sfc, "output/nat_all_projects.kml")

if(file.exists('output/nat_all_projects.shp')) {file.remove('output/nat_all_projects.shp')}
st_write(sfc, "output/nat_all_projects.shp")



