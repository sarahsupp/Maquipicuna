#Ben Weinstein - Code and Project Design
#Lisa Dittmar reviewed the videos

#Graham Lab, Stony Brook University 10/27/2013

##Competition Feeder Experiments
# A High value resource is placed alongside a low value resource
#Our goal is measure selectivity of each species at each elevation

#load in packages
require(ggplot2)
require(chron)
require(reshape)

#Set working directory
droppath<-"C:/Users/Jorge/Dropbox/Thesis//Maquipucuna_SantaLucia/"

#Define selectivity function
selective<-function(y){
  #Aggregate time by species and treatment
  Total_Time<-aggregate(y$Time_Feeder_Obs,by=list(y$Species,y$Treatment),sum, na.rm=TRUE)
  
  #Divide time on high value resource by total time on feeder
  melt.time<-melt(Total_Time)
  cast.time<-as.data.frame(cast(melt.time,Group.1~Group.2 ))
  
  #Set the NAs to 0, if bird was not present on one of the resources
  cast.time[is.na(cast.time)]<- 0
  selectivity<-cbind(cast.time,cast.time$H/(cast.time$H+cast.time$L))
  colnames(selectivity)<-c("Species","Time_High","Time_Low","Selectivity")
  
  #return output
  return(selectivity)}

##Read in data
dat<-read.csv(paste(droppath,"Data2013/csv/CompetitionFeeders.csv",sep=""))

#How many videos do we have for each elevation and treatment?
vid_totals<-aggregate(dat$Video,list(dat$Elevation,dat$Treatment),function(x) nlevels(droplevels(x)))

#Species richness and identity at each elevation
sp_matrixHL<-(table(dat$Species,dat$Elevation,dat$Treatment) >= 1) * 1

#View species at each elevation and treatment
m.sp_m<-melt(sp_matrixHL)
colnames(m.sp_m)<-c("Species","Elevation","Treatment","Presence")

#turn 0's to NA's just for plotting
m.sp_m[m.sp_m$Presence==0,"Presence"]<-NA

#View as tiles
p<-ggplot(m.sp_m,aes(y=Species,x=factor(Elevation),fill=as.factor(Presence)))+ geom_tile()  + facet_wrap(~Treatment) + theme_bw() + scale_fill_discrete(na.value="white")
p + labs(fill="Present",x="Elevation")
#ggsave()

#richness across feeders
p<-ggplot(m.sp_m,aes(y=Species,x=factor(Elevation),fill=as.factor(Presence)))+ geom_tile() + theme_bw() + scale_fill_discrete(na.value="white")
p + labs(fill="Present",x="Elevation")

#####################
#Time on the feeders
####################

#Create time columns
dat$Time.End<-times(dat$Time.End)
dat$Time.Begin<-times(dat$Time.Begin)

#Find time difference 
dat$Time_Feeder_Obs<-dat$Time.End - dat$Time.Begin

#Get any rownumbers that are negative, these need to be fixed. 
dat[which(dat$Time_Feeder_Obs < 0),]

#Total Time per species
Total_Time_Species<-aggregate(dat$Time_Feeder_Obs,by=list(dat$Species),sum) 
colnames(Total_Time_Species)<-c("Species","TotalTime")
ggplot(Total_Time_Species,aes(Species,minutes(TotalTime))) + geom_bar() + theme_bw()
#ggsave

####Match each trial together, trials are done on the same day at the same elevation
#Split data into a list, with each compenent being one trial pair
#In the future, we need to delinate by the same day?

#Trials<-split(dat, list(dat$Elevation,dat$Date),drop=TRUE)
Trials<-split(dat, list(dat$Elevation),drop=TRUE)

#####Just for data clarity remove any trials that down have high and low value data entered
#Get number of levels per trial
levels.trial<-lapply(Trials,function(x) nlevels(factor(x$Treatment)))

#Only use trials that have a high and low, ie levels=2
#complete.trial<- Trials[levels.trial ==2]

#Calculate selectivity
compet<-lapply(Trials,selective)
melt.compet<-melt(compet)

#Format table for selectivity across elevations
selective.matrix<-as.data.frame(cast(melt.compet,L1 + Species ~ variable))
selective.matrix$Time_High<-times(selective.matrix$Time_High)
selective.matrix$Time_Low<-times(selective.matrix$Time_Low)
selective.matrix$Total_Time<-selective.matrix$Time_High + selective.matrix$Time_Low

#add total minutes feeding as a weight

selective.matrix$Minutes_High<-minutes(selective.matrix$Time_High)+minutes(selective.matrix$Time_High)
selective.matrix$Minutes_Low<-minutes(selective.matrix$Time_Low)+minutes(selective.matrix$Time_Low)
selective.matrix$Minutes_Total<-selective.matrix$Minutes_Low+selective.matrix$Minutes_High

colnames(selective.matrix)[1]<-"Elevation"

#plot

#unweighted
p<-ggplot(selective.matrix,aes(x=Elevation,Selectivity,col=Species)) + geom_point(size=3) + facet_wrap(~Species) + geom_smooth(aes(group=1))
p
ggsave(paste(droppath,"Selectivity/Selectivity_Elevation_Unweighted.svg",sep=""),height=8,width=15)

#weighted
p<-ggplot(selective.matrix,aes(x=as.numeric(Elevation),Selectivity,col=Species,size=Minutes_Total)) + geom_point() + facet_wrap(~Species)
p
p  + geom_smooth(method="glm",family="binomial",aes(weight=Minutes_Total)) + theme_bw() + xlab("Elevation")

## Write selectivity tables to file
write.csv(selective.matrix,paste(droppath,"Selectivity/Selectivity_Elevation.csv",sep=""))

##########################################
#Compare Selectivity to Available Resource
##########################################
#FlowerTransects.R needs to be run first
load(paste(droppath,"Results/FlowerTransect.Rdata",sep=""))

#Create a transect R column
selective.matrix$Elev<-paste(selective.matrix$Elevation,(as.numeric(selective.matrix$Elevation) + 200),sep="_")

#Create a month column
selective.matrix$Elev

#Merge
selective.fl<-merge(fl.totals,selective.matrix)

#For now, aggregate across months?
ggplot(selective.fl,aes(x=as.numeric(TotalFlowers),Selectivity,col=Species,size=Minutes_Total)) + geom_point() + facet_wrap(~Species)

