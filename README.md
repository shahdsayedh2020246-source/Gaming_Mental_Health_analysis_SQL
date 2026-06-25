# 🎮 Gaming & Mental Health | End-to-End SQL Analytics & Data Modeling

## 📌 Project Overview
This project delivers a comprehensive, data-driven analysis exploring the relationship between **Gaming Habits and Psychological Well-being / Physical Health**. Using a dataset of 1,000 players, the project transitions from a single flat data source into a fully optimized **Star Schema** architectural model using **MySQL**.

The workflow spans data cleaning, advanced feature engineering (outlier-aware bucketing), relational dimensional modeling, and deep analytical querying to extract high-value business/health metrics and KPIs.

---

## 🛠️ Tech Stack & Key SQL Techniques
* **Database Management System:** MySQL
* **Data Cleaning & Standardization:** Data Imputation, Safe Update Configurations, Schema Alterations.
* **Feature Engineering:** Conditional Logic (`CASE WHEN`), Window Functions (`ROW_NUMBER()`), Session Variables, Statistical Aggregations (`STDDEV()`).
* **Data Modeling:** Star Schema Architecture (1 Fact Table, 6 Dimension Tables), Primary/Foreign Key Constraints, Cascade Actions (`ON UPDATE CASCADE`).
* **Advanced Analytics:** Common Table Expressions (CTEs), Multi-table Joins, Partitions, Demographic Distribution Reporting, KPI Generation.

---

## 💻 Project Workflow & Source Code

### 1️⃣ Database Setup & Data Cleaning
In this phase, I configured the database environment, handled structurally problematic table names, and performed proper data imputation by converting empty strings into true database `NULL` values for non-student and non-worker records to ensure metric calculation integrity.

```sql
-- Create and set up the project database
CREATE DATABASE IF NOT EXISTS final_project_sql;
SET SQL_SAFE_UPDATES = 0;
USE final_project_sql;

-- Standardize table identifiers
ALTER TABLE `gaming and mental health` RENAME TO gaming_mental_health;

-- Impute missing metrics by converting blank text fields to true NULL values
UPDATE gaming_mental_health SET grades_gpa = NULL WHERE grades_gpa = '';
UPDATE gaming_mental_health SET work_productivity_score = NULL WHERE work_productivity_score = '';

-- Validate record uniqueness across primary key identifiers
SELECT record_id, COUNT(*) AS duplicate_count
FROM gaming_mental_health
GROUP BY record_id
HAVING COUNT(*) > 1;
2️⃣ Advanced Feature Engineering
To deepen the analytic capabilities of the dataset, I engineered several customized, derived metrics. This includes demographic segmentation, complex multi-symptom physical risk indexing, and statistical outlier-aware profiling (using standard deviation thresholds) to classify player spending and gaming hour tiers.
-- 1. Categorize sleep patterns based on daily duration
ALTER TABLE gaming_mental_health ADD COLUMN sleep_states VARCHAR(25);
UPDATE gaming_mental_health
SET sleep_states = CASE 
    WHEN sleep_hours <= 4 THEN 'Poor'
    WHEN sleep_hours <= 8 THEN 'Healthy'
    ELSE 'Over_Sleep'
END;

-- 2. Compute Lifetime Spend & engineer standard deviation-driven Tier categories
ALTER TABLE gaming_mental_health ADD COLUMN Total_spent INT(20), ADD COLUMN Spend_Category VARCHAR(20);
UPDATE gaming_mental_health SET Total_spent = monthly_game_spending_usd * years_gaming * 12;

SELECT AVG(Total_spent), STDDEV(Total_spent) INTO @avg_spent, @std_spent FROM gaming_mental_health;
UPDATE gaming_mental_health
SET Spend_Category = CASE
    WHEN Total_spent <= @avg_spent THEN 'Low'
    WHEN Total_spent <= (@avg_spent + @std_spent) THEN 'Mid'
    WHEN Total_spent <= (@avg_spent + 2 * @std_spent) THEN 'High'
    ELSE 'Very High'
END;

-- 3. Segment demographics into explicit Age Brackets
ALTER TABLE gaming_mental_health ADD COLUMN age_group VARCHAR(50);
UPDATE gaming_mental_health
SET age_group = CASE 
    WHEN age BETWEEN 12 AND 18 THEN 'Teenager'
    WHEN age BETWEEN 19 AND 28 THEN 'Young Adult'
    ELSE 'Adult'
END;

-- 4. Proxy socioeconomic status based on academic/professional activity
ALTER TABLE gaming_mental_health ADD COLUMN Educational_State VARCHAR(20);
UPDATE gaming_mental_health
SET Educational_State = CASE 
    WHEN grades_gpa IS NOT NULL AND work_productivity_score IS NULL THEN 'Student'
    WHEN grades_gpa IS NULL AND work_productivity_score IS NOT NULL THEN 'Worker'
    WHEN grades_gpa IS NOT NULL AND work_productivity_score IS NOT NULL THEN 'Working_Student'
    ELSE 'Unknown'
END;

-- 5. Synthesize a unified Physical Symptom Risk Matrix
ALTER TABLE gaming_mental_health ADD COLUMN Physical_Pain VARCHAR(20);
UPDATE gaming_mental_health
SET Physical_Pain = CASE 
    WHEN eye_strain = 'TRUE' AND back_neck_pain = 'TRUE' THEN 'High_Risk'
    WHEN (eye_strain = 'False' AND back_neck_pain = 'TRUE') OR (eye_strain ='TRUE' AND back_neck_pain = 'False') THEN 'Moderate'
    ELSE 'NO_Risk'
END;

-- 6. Profile daily gaming intensity using population distribution statistics
ALTER TABLE gaming_mental_health ADD COLUMN Gaming_Hours_Category VARCHAR(20);
SELECT AVG(daily_gaming_hours), STDDEV(daily_gaming_hours) INTO @avg_hours, @std_hours FROM gaming_mental_health;
UPDATE gaming_mental_health
SET Gaming_Hours_Category = CASE
    WHEN daily_gaming_hours <= @avg_hours THEN 'Low'
    WHEN daily_gaming_hours <= (@avg_hours + @std_hours) THEN 'Mid'
    WHEN daily_gaming_hours <= (@avg_hours + 2 * @std_hours) THEN 'High'
    ELSE 'Very High'
END;
3️⃣ Dimensional Data Modeling (Star Schema)
To transition from a flat analytical structure to high-performance analytics, I decomposed the unnormalized table into a production-grade Star Schema. This involved normalizing attributes into 6 clear dimension lookup tables mapped to a centralized Fact table containing relational foreign key constraints.
-- Establish Dimension Lookup Tables
CREATE TABLE Dim_Platform (Platform_Id INT AUTO_INCREMENT PRIMARY KEY, gaming_platform VARCHAR(100)) ENGINE=InnoDB;
CREATE TABLE Dim_Game (Game_Id INT AUTO_INCREMENT PRIMARY KEY, game_genre VARCHAR(100), primary_game VARCHAR(255)) ENGINE=InnoDB;
CREATE TABLE Dim_Player (record_id VARCHAR(20) PRIMARY KEY, age INT, Age_Group VARCHAR(20), gender VARCHAR(20), Educational_State VARCHAR(100)) ENGINE=InnoDB;
CREATE TABLE Dim_Sleep (Sleep_Id INT AUTO_INCREMENT PRIMARY KEY, sleep_quality VARCHAR(50), sleep_disruption_frequency VARCHAR(50), Sleep_State VARCHAR(50)) ENGINE=InnoDB;
CREATE TABLE Dim_Addiction (Addiction_Id INT AUTO_INCREMENT PRIMARY KEY, withdrawal_symptoms VARCHAR(50), loss_of_other_interests VARCHAR(50), continued_despite_problems VARCHAR(50), gaming_addiction_risk_level VARCHAR(50)) ENGINE=InnoDB;
CREATE TABLE Dim_PhysicalStatus (Physical_Id INT AUTO_INCREMENT PRIMARY KEY, eye_strain VARCHAR(50), back_neck_pain VARCHAR(50), Physical_Pain VARCHAR(50)) ENGINE=InnoDB;

-- Construct Centralized Fact Table
CREATE TABLE Fact_Gaming_Mental_Health (
    record_id VARCHAR(20) PRIMARY KEY, Addiction_Id INT, Physical_Id INT, Sleep_Id INT, Game_Id INT, Platform_Id INT,
    daily_gaming_hours DECIMAL(4,2), Gaming_Hours_Category VARCHAR(50), sleep_hours DECIMAL(4,2), academic_work_performance VARCHAR(50),
    grades_gpa DECIMAL(3,2), work_productivity_score INT, mood_state VARCHAR(50), mood_swing_frequency VARCHAR(50),
    weight_change_kg DECIMAL(5,2), exercise_hours_weekly DECIMAL(4,2), social_isolation_score INT, face_to_face_social_hours_weekly DECIMAL(4,2),
    monthly_game_spending_usd DECIMAL(10,2), years_gaming INT, Total_spent INT, Spend_Category VARCHAR(50), updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_addiction FOREIGN KEY (Addiction_Id) REFERENCES Dim_Addiction(Addiction_Id),
    CONSTRAINT fk_physical FOREIGN KEY (Physical_Id) REFERENCES Dim_PhysicalStatus(Physical_Id),
    CONSTRAINT fk_sleep FOREIGN KEY (Sleep_Id) REFERENCES Dim_Sleep(Sleep_Id),
    CONSTRAINT fk_game FOREIGN KEY (Game_Id) REFERENCES Dim_Game(Game_Id),
    CONSTRAINT fk_player FOREIGN KEY (record_id) REFERENCES Dim_Player(record_id),
    CONSTRAINT fk_platform FOREIGN KEY (Platform_Id) REFERENCES Dim_Platform(Platform_Id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Populate Dimension lookup catalogs
INSERT INTO Dim_Platform (gaming_platform) SELECT DISTINCT gaming_platform FROM gaming_mental_health;
INSERT INTO Dim_Game (game_genre, primary_game) SELECT DISTINCT game_genre, primary_game FROM gaming_mental_health;
INSERT INTO Dim_Player SELECT DISTINCT record_id, age, age_group, gender, Educational_State FROM gaming_mental_health;
INSERT INTO Dim_Sleep (sleep_quality, sleep_disruption_frequency, Sleep_State) SELECT DISTINCT sleep_quality, sleep_disruption_frequency, sleep_states FROM gaming_mental_health;
INSERT INTO Dim_Addiction (withdrawal_symptoms, loss_of_other_interests, continued_despite_problems, gaming_addiction_risk_level) SELECT DISTINCT withdrawal_symptoms, loss_of_other_interests, continued_despite_problems, gaming_addiction_risk_level FROM gaming_mental_health;
INSERT INTO Dim_PhysicalStatus (eye_strain, back_neck_pain, Physical_Pain) SELECT DISTINCT eye_strain, back_neck_pain, Physical_Pain FROM gaming_mental_health;

-- Populate Fact Table via Key Resolving Joins
INSERT INTO Fact_Gaming_Mental_Health (...) 
SELECT f.record_id, a.Addiction_Id, ph.Physical_Id, s.Sleep_Id, g.Game_Id, p.Platform_Id, ...
FROM gaming_mental_health as f
LEFT JOIN dim_addiction as a ON f.withdrawal_symptoms = a.withdrawal_symptoms AND f.loss_of_other_interests = a.loss_of_other_interests AND f.continued_despite_problems = a.continued_despite_problems AND f.gaming_addiction_risk_level = a.gaming_addiction_risk_level
LEFT JOIN Dim_PhysicalStatus as ph ON f.eye_strain = ph.eye_strain AND f.back_neck_pain = ph.back_neck_pain AND f.Physical_Pain = ph.Physical_Pain
LEFT JOIN Dim_Sleep as s ON f.sleep_quality = s.sleep_quality AND f.sleep_disruption_frequency = s.sleep_disruption_frequency AND f.sleep_states = s.Sleep_State
LEFT JOIN Dim_Game as g ON f.game_genre = g.game_genre AND f.primary_game = g.primary_game
LEFT JOIN Dim_Platform as p ON f.gaming_platform = p.gaming_platform;
4️⃣ Deep Exploratory Analytics & Queries
With the Star Schema implemented, I performed cross-dimensional analytical queries. These evaluations revealed significant relationships, such as how increased daily hours correlate with physical pain, academic performance declines, financial anomalies across varying mood states, and social isolation trends.
-- 1. Top 10 Games by Cumulative Engagement Volume
SELECT g.primary_game, SUM(daily_gaming_hours) AS Sum_hours
FROM Fact_Gaming_Mental_Health f JOIN Dim_Game g ON g.Game_Id = f.Game_Id
GROUP BY g.primary_game ORDER BY Sum_hours DESC LIMIT 10;

-- 2. Top Performing Game in Daily Playtime Volume per Genre Using Window Rankings
WITH Ranking_CTE AS (
    SELECT g.game_genre, g.primary_game, ROUND(AVG(f.daily_gaming_hours),2) AS Avg_Hours,
           RANK() OVER(PARTITION BY g.game_genre ORDER BY AVG(f.daily_gaming_hours) DESC) AS Game_Rank
    FROM Fact_Gaming_Mental_Health f JOIN Dim_Game g ON f.Game_Id = g.Game_Id GROUP BY g.game_genre, g.primary_game
)
SELECT * FROM Ranking_CTE WHERE Game_Rank = 1;

-- 3. Correlation: Addiction Risk vs Social Isolation & Face-to-Face Engagement Time
SELECT a.gaming_addiction_risk_level, ROUND(AVG(f.social_isolation_score),1) AS Avg_ISO_Score, ROUND(AVG(f.face_to_face_social_hours_weekly),1) AS Avg_Face_To_Face
FROM Fact_Gaming_Mental_Health f LEFT JOIN Dim_Addiction a ON a.Addiction_Id = f.Addiction_Id
GROUP BY gaming_addiction_risk_level;

-- 4. Correlation: Interaction Between Physical Pain Risks and Playtime Tiers
SELECT physical_pain, ROUND(AVG(daily_gaming_hours),1) AS Avg_Hours
FROM Fact_Gaming_Mental_Health f LEFT JOIN Dim_PhysicalStatus ph ON ph.Physical_Id = f.Physical_Id
GROUP BY physical_pain ORDER BY Avg_Hours;

-- 5. Impact Analysis: Daily Playtime vs Academic/Work Performance Metrics
SELECT academic_work_performance, ROUND(AVG(daily_gaming_hours),2) AS avg_hours
FROM Fact_Gaming_Mental_Health GROUP BY academic_work_performance ORDER BY avg_hours DESC;
5️⃣ Comprehensive Executive KPIs
These high-level analytical queries aggregate foundational metrics across different aspects of wellness, finance, demographic shares, and behavioral patterns. They are designed to mirror corporate business intelligence card components.
-- General Population Metrics
SELECT COUNT(p.record_id) AS Total_Players,
       CONCAT(ROUND(100 * SUM(CASE WHEN p.gender = 'male' THEN 1 ELSE 0 END) / COUNT(*), 1), ' %') AS Male_Share,
       CONCAT(ROUND(100 * SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) / COUNT(*), 1), ' %') AS Female_Share,
       ROUND(AVG(f.daily_gaming_hours), 2) AS Overall_Avg_Gaming_Hours
FROM Fact_Gaming_Mental_Health f JOIN Dim_Player p ON f.record_id = p.record_id;

-- Addiction Distribution KPI Breakdown
SELECT CONCAT(ROUND(100 * SUM(CASE WHEN a.gaming_addiction_risk_level = 'Low' THEN 1 ELSE 0 END) / COUNT(*), 1), ' %') AS Low_Risk_Pct,
       CONCAT(ROUND(100 * SUM(CASE WHEN a.gaming_addiction_risk_level = 'Severe' THEN 1 ELSE 0 END) / COUNT(*), 1), ' %') AS Severe_Risk_Pct,
       ROUND(AVG(f.social_isolation_score), 2) AS Core_Isolation_Index
FROM Fact_Gaming_Mental_Health f LEFT JOIN Dim_Addiction a ON a.Addiction_Id = f.Addiction_Id;

-- Spending Analytics Tiers
SELECT SUM(Total_spent) AS Total_Lifetime_Spend, ROUND(AVG(Total_spent), 2) AS Avg_Player_LTV, ROUND(AVG(monthly_game_spending_usd), 2) AS Avg_Monthly_Velocity
FROM Fact_Gaming_Mental_Health;
