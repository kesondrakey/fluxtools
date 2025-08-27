#compare if these are the same:
test_cleanedcsv <- read.csv("C:/Users/Karmic Dreamwork.000/Downloads/test_cleanedcsv.csv")
#compare with:
#df <- read.csv("E:/Github/fluxtools/inst/extdata/US-VT1_HH_202401010000_202501010000.csv")
test_cleanedcsv$TIMESTAMP_START <- as.character(test_cleanedcsv$TIMESTAMP_START)



# 0) (if needed) read your saved CSV the same way the app writes it
# test_cleanedcsv <- read.csv("fluxtools_processed.csv", stringsAsFactors = FALSE)

# 1) Strict: must match types, order, attributes, everything
identical(df, test_cleanedcsv)

# 2) Flexible: ignore attributes
all.equal(df, test_cleanedcsv, check.attributes = FALSE, tolerance = 0)

summary(df)
summary(test_cleanedcsv)

#all equal = true!
# > identical(df, test_cleanedcsv)
# [1] FALSE
# > # 2) Flexible: ignore attributes; allow tiny numeric differences
#   > all.equal(df, test_cleanedcsv, check.attributes = FALSE, tolerance = 1e-8)
# [1] "Component “TIMESTAMP_START”: target is character, current is numeric"

summary(df)
summary(test_cleanedcsv)






na_vals <- c('NA','NaN','','-9999','-9999.0','-9999.00','-9999.000')
cc <- c('TIMESTAMP_START'='character',  # plus the numeric columns you embedded
        'FC_1_1_1'='numeric','ALB'='numeric', ...)

test <- read.csv("fluxtools_processed.csv",
                 stringsAsFactors = FALSE,
                 na.strings = na_vals,
                 colClasses = cc)

identical(df, test)                # should be TRUE
# or:
all.equal(df, test, check.attributes = FALSE, tolerance = 0)
