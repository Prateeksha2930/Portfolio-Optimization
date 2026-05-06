#-------------------------------------------------------------------------------
# Step 1: Connect DB to db stockmarket
#-------------------------------------------------------------------------------
  require(RPostgres)  # load driver
  conn <- dbConnect(RPostgres::Postgres(),
                    user="stockmarketreader",
                    password="read123",
                    host="postgres", #locahost if run on R Studio
                    port=5432,
                    dbname="stockmarket"
  )

#-------------------------------------------------------------------------------
# Step 2: Data Retrieval
#-------------------------------------------------------------------------------
  qry <- 'SELECT * FROM custom_calendar ORDER by date'
  ccal <- dbGetQuery(conn, qry) #store select qry to ccal: custom_calendar
  
  #union qry1 and qry2 into eod data frame
    qry1="SELECT symbol,date,adj_close FROM eod_indices WHERE date BETWEEN '2015-12-31' AND '2021-03-26'"
    qry2="SELECT ticker,date,adj_close FROM eod_quotes WHERE date BETWEEN '2015-12-31' AND '2021-03-26'"
  eod  <- dbGetQuery(conn, paste(qry1,'UNION',qry2)) #store select qry1+qry2 to eod
  
  #Disconnect and remove connection
    dbDisconnect(conn); 
    rm(conn)
  
#-------------------------------------------------------------------------------
# Step 3: Data Preparation
#-------------------------------------------------------------------------------
  #Export the Trading day using DB ccal where trading = 1  
    tdays<-ccal[which(ccal$trading==1),,drop=F]
  
  #Check Completeness: Ensure each symbol has ≥99% of trading days
    pct<-table(eod$symbol)/(nrow(tdays)-1);
    selected_symbols_daily<-names(pct)[which(pct>=0.99)];
    
  #Store all the symbols which belong good list (99%) from eod to eod_complete
    eod_complete<-eod[which(eod$symbol %in% selected_symbols_daily),,drop=F]
  
  #Convert data from eod_complete to pivot table
    require(reshape2)
    eod_pvt<-dcast(eod_complete, date ~ symbol,
                   value.var='adj_close',fun.aggregate = mean, fill=NULL)
  
  #Merging tdays and eod_pvt
    eod_pvt_complete <- 
      merge.data.frame(
        x = tdays[,'date', drop = FALSE], 
        y = eod_pvt, 
        by = 'date', 
        all.x = TRUE 
      )
  
  #Change rowname to date
    rownames(eod_pvt_complete)<-eod_pvt_complete$date
    
  #Remove date column from eod_pvt_complete
    eod_pvt_complete$date<-NULL;
  
  #Replace a few missing (NA or NaN) with previous data
  # using LOCF: Last Observation Carried Forward
    require(zoo)
    eod_pvt_complete <- na.locf(
      eod_pvt_complete, 
      na.rm = FALSE,    
      fromLast = FALSE, 
      maxgap = 3        
    )
  
#-------------------------------------------------------------------------------
# Step 4: Calculating Returns
#------------------------------------------------------------------------------- 
    #load package PerformanceAnalytics and calc Return to eod_ret
      require(PerformanceAnalytics)
      eod_ret<-CalculateReturns(eod_pvt_complete)
  
    #remove the first row with NA
      eod_ret<-tail(eod_ret,-1)
      
    #Extreme Returns Check
      #create function colMax : return max return in column
        colMax <- function(data) sapply(data, max, na.rm = TRUE)
      
      #Calculate max daily return in eod_ret
        max_daily_ret<-colMax(eod_ret)
  
      #Check completeness
        selected_symbols_daily<-names(max_daily_ret)[which(max_daily_ret<=1.00)]
      
      #subset eod_ret with selected_symbols_daily
        eod_ret<-eod_ret[,which(colnames(eod_ret) %in% selected_symbols_daily),drop=F]

      #Export eod_ret.csv
        #write.csv(eod_ret,'eod_ret.csv')
        
#-------------------------------------------------------------------------------
# Step 5: Optimizing Portfolio
#-------------------------------------------------------------------------------
  #Store return of assigned ticker to Ra
    tickers <- c(
                  'SSRM','CMTV','GHM', #Do, Duy
                  'TTC','HOPE','LPL',  #Cabral, Juliet
                  'PFE','IHG','CSL',  #Canas, Carolina
                  'SATS','SNX','MTRX',  #Mehta, Prateeksha
                  'NGG','ST','MCO'  #Sanandiya, Preet	
                  )
    Ra <- as.xts(eod_ret[, tickers, drop = FALSE])
  
  #Store return of SP500TR to Rb
    Rb <- as.xts(eod_ret[, 'SP500TR', drop = FALSE])
    
  #Training: 2016-01-01 to 2020-12-31
    Ra_training <- Ra["2016-01-01/2020-12-31"]
    Rb_training <- Rb["2016-01-01/2020-12-31"]
    
  #Test: 2021-01-01 to 2021-03-26
    Ra_testing <- Ra["2021-01-01/2021-03-26"]
    Rb_testing <- Rb["2021-01-01/2021-03-26"]
    
  #Cumulative returns chart
    require(plotly)
    chart.CumReturns(cbind(Ra_training, Rb_training), legend.loc = 'topleft', plot.engine = "plotly")
    
  #Optimize the MV (Markowitz 1950s) portfolio weights based on training
  #Desc: Find me a portfolio using these assets, 
  #      where all the money is invested (weights sum to 1), 
  #      the expected return is at least mar, and among all such portfolios, 
  #      minimize the standard deviation (risk)
    
    #Load packages needed
      require(PortfolioAnalytics);
      require(ROI);
      require(ROI.plugin.quadprog)
    
    #Benchmark summary
      table.AnnualizedReturns(Rb_training)
    
    #Set the return target (MAR)
      mar<-mean(Rb_training)
    
    #Specify the asset universe
      pspec<-portfolio.spec(assets=colnames(Ra_training))
    
    #Objective: minimize risk, minimize portfolio standard deviation
      pspec<-add.objective(portfolio=pspec,type="risk",name='StdDev')
    
    #Constraint: fully invested, Sum of weights = 1
      pspec<-add.constraint(portfolio=pspec,type="full_investment")
    
    #Constraint: minimum return, Enforces expected portfolio return ≥ mar
      pspec<-add.constraint(portfolio=pspec,type="return",return_target=mar)
    
    #Solve: optimize portfolio
      opt_p<-optimize.portfolio(R=Ra_training,portfolio=pspec,optimize_method = 'ROI')
        
    #extract weights (negative weights means shorting)
      opt_w<-opt_p$weights
      
    #sum of weights
      sum <- sum(opt_w)
      
    #apply weights to test returns
      Rp<-Rb_testing
    
    #Taking optimized weights & applying them to the out-of-sample returns (Ra_testing) 
    #to compute the portfolio’s performance during the test window
      Rp$ptf<-Ra_testing %*% opt_w
        
    #Check
      head(Rp); tail(Rp)
    
    #Showing chart compare SP500 with Portforlio
      table.AnnualizedReturns(Rp)
      
      library(graphics)    # <- ensures axis() exists
      chart.CumReturns(Rp, legend.loc = 'bottomright')
    
    #Showing Weights
      View(opt_w)
        
        
        
        
        
        
        
        