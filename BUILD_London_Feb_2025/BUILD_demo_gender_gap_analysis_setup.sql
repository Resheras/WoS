CREATE database BUILD_EVENT;
CREATE schema BUILD_DEMO;
USE database BUILD_EVENT;
USE schema BUILD_DEMO;
CREATE stage BUILD_RAW_DATA;
--add file to stage from data tab https://www.kaggle.com/datasets/nilimajauhari/glassdoor-analyze-gender-pay-gap
LIST @BUILD_RAW_DATA;
CREATE TABLE SALARY_DATA (
JobTitle VARCHAR(255),
Gender VARCHAR(20),
Age NUMBER,
PerfEval NUMBER,
Education VARCHAR(255),
Dept VARCHAR(255),
Seniority NUMBER,
BasePay NUMBER,
Bonus NUMBER
);
COPY INTO SALARY_DATA
FROM @BUILD_RAW_DATA
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1);

