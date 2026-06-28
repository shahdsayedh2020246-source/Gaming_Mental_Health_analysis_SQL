# 🎮 Gaming & Mental Health: Relational Database Design & Analytics

<p align="center">
  <img src="https://img.shields.io/badge/MySQL-8.0+-blue?style=for-the-badge&logo=mysql" alt="MySQL">
  <img src="https://img.shields.io/badge/Database-Star%20Schema-green?style=for-the-badge" alt="Star Schema">
  <img src="https://img.shields.io/badge/Data-Analytics%20%26%20KPIs-orange?style=for-the-badge" alt="Analytics">
</p>

## 👥 The Team: The Outliers
* **Members:** Mohamed Bedier, Belal Ahmed, Shahd Mohamed Sayed, Youssef Talaat, Ibrahim Elnemer
* **Supervised by:** 💌 Dr. Amal Mahmoud 💌

---

## 📌 1. Project Overview
This project delivers an end-to-end relational database solution to study the deep intersection between digital gaming habits and human physical/psychological well-being. Using a raw dataset of **1,000 players**, we designed and populated an optimized relational model to extract clear, data-driven answers regarding how intense screen hours relate to addiction levels, financial spend, sleep deprivation, and performance metrics.

---

## 📊 2. Relational Database Design (Star Schema)
To transition from a flat, unoptimized dataset to a high-performance analytics system, the database was architected using a **Star Schema** centered around detailed surrogate-keyed dimensions.

### 📐 Schema Visual Representation
The structural mapping between tables can be reviewed directly via the verbatim file **ERD Diagram.jpg**:

<p align="center">
  <img src="ERD Diagram.jpg" alt="ERD Diagram" width="85%"/>
</p>

### 🔗 Architectural Components
1. **`Fact_Gaming_Mental_Health` (Central Fact Table)**: Stores quantitative behavioral metrics and foreign keys referencing 6 dimension lookup engines.
2. **`Dim_Player`**: Manages demographic profiles (Age, Gender, Age Group, Educational State).
3. **`Dim_Game`**: Normalizes unique gaming genres paired with specific primary game titles.
4. **`Dim_Platform`**: Stores categorical data of gaming hardware (PC, Console, Mobile, Multi-platform).
5. **`Dim_Sleep`**: Tracks metrics like sleep quality, disturbance frequencies, and grouped sleep health labels.
6. **`Dim_Addiction`**: Isolates behavioral patterns including withdrawal symptoms, social escapism indicators, and structured clinical risk levels.
7. **`Dim_PhysicalStatus`**: Registers concrete physical conditions such as eye strain and cervical/posture pain indicators.

### 📋 Tables Relationships & Constraints Matrix

تم بناء العلاقات على نموذج (One-to-Many / 1:N) حيث تمثل جداول الأبعاد (Dimension Tables) الجانب الفردي (1)، ويمثل جدول الحقائق المركزي (Fact Table) الجانب المتعدد (N).

<table>
  <thead>
    <tr style="background-color: #f2f2f2;">
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Primary Table (Dimension)</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Primary Key (PK)</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Foreign Key (FK) in Fact Table</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Relationship Type</th>
      <th style="padding: 10px; border: 1px solid #ddd; text-align: left;">On Update / On Delete Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding: 10px; border: 1px solid #ddd;"><b>Dim_Player</b></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>record_id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>record_id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;">1 : 1 (Strict Owner Lookup)</td>
      <td style="padding: 10px; border: 1px solid #ddd;">RESTRICT / RESTRICT</td>
    </tr>
    <tr style="background-color: #f9f9f9;">
      <td style="padding: 10px; border: 1px solid #ddd;"><b>Dim_Game</b></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Game_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Game_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;">1 : N (One game to many records)</td>
      <td style="padding: 10px; border: 1px solid #ddd;">RESTRICT / RESTRICT</td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid #ddd;"><b>Dim_Platform</b></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Platform_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Platform_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;">1 : N (One platform to many records)</td>
      <td style="padding: 10px; border: 1px solid #ddd;"><span style="color: green;"><b>CASCADE / SET NULL</b></span></td>
    </tr>
    <tr style="background-color: #f9f9f9;">
      <td style="padding: 10px; border: 1px solid #ddd;"><b>Dim_Sleep</b></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Sleep_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Sleep_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;">1 : N (One sleep behavior to many records)</td>
      <td style="padding: 10px; border: 1px solid #ddd;">RESTRICT / RESTRICT</td>
    </tr>
    <tr>
      <td style="padding: 10px; border: 1px solid #ddd;"><b>Dim_Addiction</b></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Addiction_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Addiction_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;">1 : N (One addiction profile to many records)</td>
      <td style="padding: 10px; border: 1px solid #ddd;">RESTRICT / RESTRICT</td>
    </tr>
    <tr style="background-color: #f9f9f9;">
      <td style="padding: 10px; border: 1px solid #ddd;"><b>Dim_PhysicalStatus</b></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Physical_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;"><code>Physical_Id</code></td>
      <td style="padding: 10px; border: 1px solid #ddd;">1 : N (One health state to many records)</td>
      <td style="padding: 10px; border: 1px solid #ddd;">RESTRICT / RESTRICT</td>
    </tr>
  </tbody>
</table>

---

## 🛠️ 3. SQL Pipeline: Implementation Code

### Phase 1: Environment Settings & Data Refinement
```sql
-- Create and switch context to the project database
CREATE DATABASE IF NOT EXISTS final_project_sql;
USE final_project_sql;

-- Disable Safe Updates for structural bulk engineering adjustments
SET SQL_SAFE_UPDATES = 0;

-- Normalize Raw Table Name
ALTER TABLE `gaming and mental health` RENAME TO gaming_mental_health;

-- Convert empty strings to proper relational NULL values
UPDATE gaming_mental_health SET grades_gpa = NULL WHERE grades_gpa = '';
UPDATE gaming_mental_health SET work_productivity_score = NULL WHERE work_productivity_score = '';
Phase 2: Feature Engineering & Threshold Segmentation
-- 1. Sleep Segmentation
ALTER TABLE gaming_mental_health ADD COLUMN sleep_states VARCHAR(25);
UPDATE gaming_mental_health SET sleep_states = CASE 
    WHEN sleep_hours <= 4 THEN 'Poor' 
    WHEN sleep_hours <= 8 THEN 'Healthy' 
    ELSE 'Over_Sleep' 
END;

-- 2. Financial Metrics & Outlier-Aware Spend Tiers
ALTER TABLE gaming_mental_health ADD COLUMN Total_spent INT(20);
UPDATE gaming_mental_health SET Total_spent = monthly_game_spending_usd * years_gaming * 12;

SELECT AVG(Total_Spent), STDDEV(Total_Spent) INTO @avg_spent, @std_spent FROM gaming_mental_health;

ALTER TABLE gaming_mental_health ADD COLUMN Spend_Category VARCHAR(20);
UPDATE gaming_mental_health SET Spend_Category = CASE
    WHEN Total_Spent <= @avg_spent THEN 'Low'
    WHEN Total_Spent <= (@avg_spent + @std_spent) THEN 'Mid'
    WHEN Total_Spent <= (@avg_spent + 2 * @std_spent) THEN 'High'
    ELSE 'Very High'
END;

-- 3. Demographic Age Buckets
ALTER TABLE gaming_mental_health ADD COLUMN age_group VARCHAR(50);
UPDATE gaming_mental_health SET age_group = CASE 
    WHEN age BETWEEN 12 AND 18 THEN 'Teenager'
    WHEN age BETWEEN 19 AND 28 THEN 'Young Adult'
    ELSE 'Adult'
END;

-- 4. Socio-Economic / Educational Proxy Classification
ALTER TABLE gaming_mental_health ADD COLUMN Educational_State VARCHAR(20);
UPDATE gaming_mental_health SET Educational_State = CASE 
    WHEN grades_gpa IS NOT NULL AND work_productivity_score IS NULL THEN 'Student'
    WHEN grades_gpa IS NULL AND work_productivity_score IS NOT NULL THEN 'Worker'
    WHEN grades_gpa IS NOT NULL AND work_productivity_score IS NOT NULL THEN 'Working_Student'
    ELSE 'Unknown'
END;

-- 5. Physical Symptom Composite Risks
ALTER TABLE gaming_mental_health ADD COLUMN Physical_Pain VARCHAR(20);
UPDATE gaming_mental_health SET Physical_Pain = CASE 
    WHEN eye_strain = 'TRUE' AND back_neck_pain = 'TRUE' THEN 'High_Risk'
    WHEN (eye_strain = 'False' AND back_neck_pain = 'TRUE') OR (eye_strain = 'TRUE' AND back_neck_pain = 'False') THEN 'Moderate'
    ELSE 'NO_Risk'
END;

-- 6. Intensive Hour Tiering via Standard Deviations
SELECT AVG(daily_gaming_hours), STDDEV(daily_gaming_hours) INTO @avg_hours, @std_hours FROM gaming_mental_health;

ALTER TABLE gaming_mental_health ADD COLUMN Gaming_Hours_Category VARCHAR(20);
UPDATE gaming_mental_health SET Gaming_Hours_Category = CASE
    WHEN daily_gaming_hours <= @avg_hours THEN 'Low'
    WHEN daily_gaming_hours <= (@avg_hours + @std_hours) THEN 'Mid'
    WHEN daily_gaming_hours <= (@avg_hours + 2 * @std_hours) THEN 'High'
    ELSE 'Very High'
END;
Phase 3: Star Schema Generation & Population
-- Create Dimension Structures
CREATE TABLE IF NOT EXISTS Dim_Platform (
    Platform_Id INT AUTO_INCREMENT PRIMARY KEY, gaming_platform VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Dim_Game (
    Game_Id INT AUTO_INCREMENT PRIMARY KEY, game_genre VARCHAR(100), primary_game VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Dim_Player (
    record_id VARCHAR(20) PRIMARY KEY, age INT, Age_Group VARCHAR(20), gender VARCHAR(20), Educational_State VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Dim_Sleep (
    Sleep_Id INT AUTO_INCREMENT PRIMARY KEY, sleep_quality VARCHAR(50), sleep_disruption_frequency VARCHAR(50), Sleep_State VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Dim_Addiction (
    Addiction_Id INT AUTO_INCREMENT PRIMARY KEY, withdrawal_symptoms VARCHAR(50), loss_of_other_interests VARCHAR(50), continued_despite_problems VARCHAR(50), gaming_addiction_risk_level VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Dim_PhysicalStatus (
    Physical_Id INT AUTO_INCREMENT PRIMARY KEY, eye_strain VARCHAR(50), back_neck_pain VARCHAR(50), Physical_Pain VARCHAR(50)
) ENGINE=InnoDB;

-- Create Central Fact Structure
CREATE TABLE IF NOT EXISTS Fact_Gaming_Mental_Health (
    record_id VARCHAR(20) PRIMARY KEY, Addiction_Id INT, Physical_Id INT, Sleep_Id INT, Game_Id INT, Platform_Id INT,
    daily_gaming_hours DECIMAL(4,2), Gaming_Hours_Category VARCHAR(50), sleep_hours DECIMAL(4,2), academic_work_performance VARCHAR(50),
    grades_gpa DECIMAL(3,2), work_productivity_score INT, mood_state VARCHAR(50), mood_swing_frequency VARCHAR(50),
    weight_change_kg DECIMAL(5,2), exercise_hours_weekly DECIMAL(4,2), social_isolation_score INT, face_to_face_social_hours_weekly DECIMAL(4,2),
    monthly_game_spending_usd DECIMAL(10,2), years_gaming INT, Total_spent INT, Spend_Category VARCHAR(50),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_addiction FOREIGN KEY (Addiction_Id) REFERENCES Dim_Addiction(Addiction_Id),
    CONSTRAINT fk_physical FOREIGN KEY (Physical_Id) REFERENCES Dim_PhysicalStatus(Physical_Id),
    CONSTRAINT fk_sleep FOREIGN KEY (Sleep_Id) REFERENCES Dim_Sleep(Sleep_Id),
    CONSTRAINT fk_game FOREIGN KEY (Game_Id) REFERENCES Dim_Game(Game_Id),
    CONSTRAINT fk_player FOREIGN KEY (record_id) REFERENCES Dim_Player(record_id),
    CONSTRAINT fk_platform FOREIGN KEY (Platform_Id) REFERENCES Dim_Platform(Platform_Id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Populate Lookup Records
INSERT INTO Dim_Platform (gaming_platform) SELECT DISTINCT gaming_platform FROM gaming_mental_health;
INSERT INTO Dim_Game (game_genre, primary_game) SELECT DISTINCT game_genre, primary_game FROM gaming_mental_health;
INSERT INTO Dim_Player SELECT DISTINCT record_id, age, age_group, gender, Educational_State FROM gaming_mental_health;
INSERT INTO Dim_Sleep (sleep_quality, sleep_disruption_frequency, Sleep_State) SELECT DISTINCT sleep_quality, sleep_disruption_frequency, sleep_states FROM gaming_mental_health;
INSERT INTO Dim_Addiction (withdrawal_symptoms, loss_of_other_interests, continued_despite_problems, gaming_addiction_risk_level) SELECT DISTINCT withdrawal_symptoms, loss_of_other_interests, continued_despite_problems, gaming_addiction_risk_level FROM gaming_mental_health;
INSERT INTO Dim_PhysicalStatus (eye_strain, back_neck_pain, Physical_Pain) SELECT DISTINCT eye_strain, back_neck_pain, Physical_Pain FROM gaming_mental_health;

-- Populate Fact Table via Key Resolution
INSERT INTO Fact_Gaming_Mental_Health 
SELECT f.record_id, a.Addiction_Id, ph.Physical_Id, s.Sleep_Id, g.Game_Id, p.Platform_Id, f.daily_gaming_hours, f.Gaming_Hours_Category, f.sleep_hours, f.academic_work_performance, f.grades_gpa, f.work_productivity_score, f.mood_state, f.mood_swing_frequency, f.weight_change_kg, f.exercise_hours_weekly, f.social_isolation_score, f.face_to_face_social_hours_weekly, f.monthly_game_spending_usd, f.years_gaming, f.Total_spent, f.Spend_Category 
FROM gaming_mental_health AS f
LEFT JOIN Dim_Addiction AS a ON f.withdrawal_symptoms = a.withdrawal_symptoms AND f.loss_of_other_interests = a.loss_of_other_interests AND f.continued_despite_problems = a.continued_despite_problems AND f.gaming_addiction_risk_level = a.gaming_addiction_risk_level
LEFT JOIN Dim_PhysicalStatus AS ph ON f.eye_strain = ph.eye_strain AND f.back_neck_pain = ph.back_neck_pain AND f.Physical_Pain = ph.Physical_Pain
LEFT JOIN Dim_Sleep AS s ON f.sleep_quality = s.sleep_quality AND f.sleep_disruption_frequency = s.sleep_disruption_frequency AND f.sleep_states = s.Sleep_State
LEFT JOIN Dim_Game AS g ON f.game_genre = g.game_genre AND f.primary_game = g.primary_game
LEFT JOIN Dim_Platform AS p ON f.gaming_platform = p.gaming_platform;
📈 4. Advanced Analytical Insights & Business Queries
Query 1: Top 5 Highest Average Engagement Games per Genre
WITH CTE_Rank AS (
    SELECT g.game_genre, g.primary_game, ROUND(AVG(f.daily_gaming_hours), 2) AS Avg_Hours,
           RANK() OVER(PARTITION BY g.game_genre ORDER BY AVG(f.daily_gaming_hours) DESC) AS Game_Rank
    FROM Fact_Gaming_Mental_Health f JOIN Dim_Game g ON f.Game_Id = g.Game_Id
    GROUP BY g.game_genre, g.primary_game
)
SELECT game_genre, primary_game, Avg_Hours FROM CTE_Rank WHERE Game_Rank = 1;
Empirical Peak Findings: Apex Legends leads Battle Royale (7.21 hrs/day), Civilization VI leads Strategy (6.79 hrs/day), and Final Fantasy XIV leads MMO categories (6.69 hrs/day).

Query 2: Behavioral Impact (Addiction vs Isolation Parameters)
SELECT a.gaming_addiction_risk_level, 
       ROUND(AVG(f.social_isolation_score), 1) AS Avg_ISO_Score,
       ROUND(AVG(f.face_to_face_social_hours_weekly), 1) AS Avg_Face_To_Face
FROM Fact_Gaming_Mental_Health f LEFT JOIN Dim_Addiction a ON a.Addiction_Id = f.Addiction_Id
GROUP BY gaming_addiction_risk_level;
Insight: Confirms a clear linear trend. Severe clinical addiction risks map directly to elevated isolation indexes (6.5 score) and minimal face-to-face real-world interactions (3.2 hours weekly).

Query 3: Physical Risk Correlations
SELECT physical_pain, ROUND(AVG(daily_gaming_hours), 1) AS Avg_Hours
FROM Fact_Gaming_Mental_Health f LEFT JOIN Dim_PhysicalStatus ph ON ph.Physical_Id = f.Physical_Id
GROUP BY physical_pain ORDER BY Avg_Hours;
Insight: Hardcore engagement cohorts (>8 hours daily) show a near 100% presence of overlapping eye strain and musculoskeletal symptoms (High Risk category).📊 5. Structured Executive KPI DashboardsThe analytical queries yield clear high-level metrics across five core pillars:I. General DemographicsTotal Player Cohort: 1,000 active profilesGender Ratio Breakdown: Male: 64.7% | Female: 33.1% | Other: 2.2%Mean Macro Engagement: 6.15 Hours DailyII. Well-being & Biological MetricsAverage Sleep Duration: 5.74 Hours/Night (Indicates widespread sleep debt)Weekly Physical Activity Mean: 6.95 HoursAverage Tracked Weight Fluctuations: +1.51 kgIII. Addiction & Social Strain MetricsRisk Group Ratios: Low: 51.4% | Moderate: 19.0% | High: 15.4% | Severe: 14.2%Average Isolation Metric: 3.87 / 10Mean Live Socialization: 7.65 Hours / WeekIV. Commercial Ecosystem MetricsAccumulated Life Spend: $7,204,604 USDMean Historical Value Per User: $7,204.60 USDMean Microtransaction Volatility: $105.22 USD MonthlyV. Performance Indicators (Academic vs Workforce)Gender GroupAverage Academic GPAWorkplace Productivity (Scale 1-10)Male2.505.40Female2.575.33Other2.256.13🚀 How To Run & Deploy LocallyClone this project repository down to your secure workstation environment:
git clone [https://github.com/YOUR_USERNAME/Gaming_Mental_Health_Analysis_python.git](https://github.com/YOUR_USERNAME/Gaming_Mental_Health_Analysis_python.git)
Fire up your preferred instance tool (e.g., MySQL Workbench or Command Line Interface).

Execute the full script layout saved inside gaming_analysis_pipeline.sql to systematically build out and populate the analytical model layers.
