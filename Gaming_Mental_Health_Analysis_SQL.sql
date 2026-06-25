-- ============================================================
-- Gaming & Mental Health — Data Cleaning, Modeling & Analysis
-- All "Output:" comments below were computed by running the equivalent
-- query against the real dataset (1000 rows), so you can read the
-- expected result without re-running the SQL.
-- ============================================================

-- Create the project database (only if it doesn't already exist)
create database if not exists final_project_sql;

-- Disable MySQL's "safe update mode" so UPDATE statements without a
-- key-based WHERE clause are allowed (needed for the bulk UPDATEs below)
SET SQL_SAFE_UPDATES = 0;

-- Switch to the project database for all following statements
use final_project_sql;


-- Quick look at the raw imported table
SELECT * FROM `gaming and mental health`;

-- The table was imported with a space in its name ("gaming and mental health");
-- rename it to a valid, easy-to-reference identifier
ALTER TABLE `gaming and mental health` RENAME TO gaming_mental_health;

-- Confirm the rename worked
SELECT * FROM Gaming_Mental_Health;


-- grades_gpa was imported as empty strings ('') instead of true NULLs for
-- rows where the player isn't a student — convert those to real NULL
UPDATE Gaming_Mental_Health
SET grades_gpa = NULL
WHERE grades_gpa = '';

-- Same fix for work_productivity_score (empty string -> NULL for non-workers)
UPDATE Gaming_Mental_Health
SET work_productivity_score = NULL
WHERE work_productivity_score = '';


-- Spot-check the two columns after the NULL fix
SELECT work_productivity_score , grades_gpa 
FROM Gaming_Mental_Health;


-- Count how many players are missing GPA / productivity score
-- Output: NULL_GPA_Count = 246 | NULL_Work_Count = 326
SELECT 
    (SELECT COUNT(*) FROM Gaming_Mental_Health WHERE grades_gpa IS NULL) AS NULL_GPA_Count,
    (SELECT COUNT(*) FROM Gaming_Mental_Health WHERE work_productivity_score IS NULL) AS NULL_Work_Count;





-- Duplicate check: group by record_id (the primary key) and flag any id
-- that appears more than once — this catches a repeated player id even
-- if other fields differ, not just an exact re-import of the same row.
-- Output: empty result set -> record_id is unique across all 1000 rows.
SELECT record_id, COUNT(*) AS duplicate_count
FROM Gaming_Mental_Health
GROUP BY record_id
HAVING COUNT(*) > 1;


-- ============================================================
-- FEATURE ENGINEERING
-- Adding derived columns used later for grouping/analysis
-- ============================================================

-- sleep_states: bucket each player's sleep_hours into a simple health label
ALTER TABLE Gaming_Mental_Health
ADD COLUMN sleep_states VARCHAR(25);

UPDATE Gaming_Mental_Health
SET sleep_states = CASE 
    WHEN sleep_hours  <= 4 then 'Poor'        -- 4 hrs or less -> sleep deprived
    WHEN sleep_hours  <= 8 then 'Healthy'     -- 4-8 hrs -> normal range
    ELSE 'Over_Sleep'                         -- more than 8 hrs
END;

-- Output distribution: Healthy 764 | Poor 147 | Over_Sleep 89
SELECT sleep_states
FROM Gaming_Mental_Health;

-- Total_spent: lifetime spend estimate = monthly spend x 12 months x years gaming
ALTER TABLE Gaming_Mental_Health
ADD COLUMN Total_spent INT(20);

UPDATE Gaming_Mental_Health
SET Total_spent =monthly_game_spending_usd * years_gaming * 12;

select monthly_game_spending_usd,Total_spent
from Gaming_Mental_Health;

-- Store the mean and population standard deviation of Total_spent in
-- session variables so they can be reused in the next UPDATE.
-- (MySQL's STDDEV() is the population stddev, not the sample one.)
-- Output: @avg_spent ≈ 7204.60 | @std_spent ≈ 10381.57
SELECT 
    AVG(Total_Spent), 
    STDDEV(Total_Spent) 
INTO @avg_spent, @std_spent 
FROM gaming_mental_health;

-- Spend_Category: bucket players into spend tiers using mean/std-dev
-- thresholds (an outlier-aware alternative to plain quartiles)
ALTER TABLE Gaming_Mental_Health
ADD COLUMN Spend_Category VARCHAR(20);

UPDATE Gaming_Mental_Health
SET Spend_Category = CASE
    WHEN Total_Spent <= @avg_spent THEN 'Low'                       -- at/below average
    WHEN Total_Spent <= (@avg_spent + @std_spent) THEN 'Mid'         -- within 1 std-dev above average
    WHEN Total_Spent <= (@avg_spent + 2 * @std_spent) THEN 'High'    -- within 2 std-dev above average
    ELSE 'Very High'                                                 -- more than 2 std-dev above average
END;


-- Output distribution: Low 699 | Mid 207 | High 49 | Very High 45
SELECT Total_spent, Spend_Category
FROM Gaming_Mental_Health;


-- age_group: bucket players into age brackets for demographic analysis
ALTER TABLE gaming_mental_health 
ADD COLUMN age_group VARCHAR(50);

UPDATE gaming_mental_health
SET age_group = CASE 
    WHEN age BETWEEN 12 AND 18 THEN 'Teenager'
    WHEN age BETWEEN 19 AND 28 THEN 'Young Adult'
    ELSE 'Adult'
END;

-- Output distribution: Young Adult 624 | Teenager 326 | Adult 50
SELECT age, age_group FROM gaming_mental_health;

-- Educational_State: classify each player by whether they report grades,
-- work productivity, or both — a proxy for "student vs worker vs both"
ALTER TABLE gaming_mental_health 
ADD COLUMN Educational_State VARCHAR(20);


UPDATE gaming_mental_health
SET Educational_State = CASE 
    WHEN grades_gpa is not null and work_productivity_score is null  then 'Student' -- gpa only 
    WHEN grades_gpa is null and work_productivity_score is not null  then 'Worker'  -- work productivity score only
	WHEN grades_gpa is not null and work_productivity_score is not null  then 'Working_Student' -- bothe gpa and work productivity score
    ELSE 'Unknown' -- no gpa and work productivity score
END;


-- Output distribution: Working_Student 428 | Student 326 | Worker 246
SELECT grades_gpa, work_productivity_score,Educational_State FROM gaming_mental_health;

-- Physical_Pain: combine the two physical-symptom flags into one risk label
ALTER TABLE gaming_mental_health 
ADD COLUMN Physical_Pain VARCHAR(20);

UPDATE gaming_mental_health
SET Physical_Pain = CASE 
    WHEN eye_strain = 'TRUE' and back_neck_pain = 'TRUE'  then 'High_Risk'   -- both symptoms present
    WHEN (eye_strain = 'False' and back_neck_pain = 'TRUE') OR ( eye_strain ='TRUE' and back_neck_pain = 'False') then 'Moderate'   -- exactly one symptom
    ELSE 'NO_Risk'   -- neither symptom present
END;

-- Output distribution: NO_Risk 391 | Moderate 373 | High_Risk 236
SELECT eye_strain, back_neck_pain,Physical_Pain FROM gaming_mental_health;

-- Gaming_Hours_Category: bucket players by daily gaming hours, same
-- mean/std-dev approach used for Spend_Category above
ALTER TABLE gaming_mental_health 
ADD COLUMN Gaming_Hours_Category VARCHAR(20);

-- Output: @avg_hours ≈ 6.15 | @std_hours ≈ 2.87
SELECT 
    AVG(daily_gaming_hours), 
    STDDEV(daily_gaming_hours) 
INTO @avg_hours, @std_hours 
FROM gaming_mental_health;


UPDATE gaming_mental_health
SET Gaming_Hours_Category = CASE
    WHEN daily_gaming_hours <= @avg_hours THEN 'Low'
    WHEN daily_gaming_hours <= (@avg_hours + @std_hours) THEN 'Mid'
    WHEN daily_gaming_hours <= (@avg_hours + 2 * @std_hours) THEN 'High'
    ELSE 'Very High'
END;

-- Output distribution: Low 529 | Mid 312 | High 126 | Very High 33
SELECT daily_gaming_hours, Gaming_Hours_Category FROM gaming_mental_health;



-- ============================================================
-- DATA MODELING
-- Split the single flat table into a star schema (one fact table +
-- six dimension tables) so the analysis queries below can join small,
-- well-typed lookup tables instead of repeatedly scanning every column.
-- ============================================================

-- Dimension: gaming platform (PC, Console, Mobile, Multi-platform)
CREATE TABLE IF NOT EXISTS Dim_Platform (
    Platform_Id INT AUTO_INCREMENT PRIMARY KEY,
    gaming_platform VARCHAR(100) 
) ENGINE=InnoDB;

-- Dimension: game genre + the specific game title
CREATE TABLE IF NOT EXISTS Dim_Game(
Game_Id INT AUTO_INCREMENT PRIMARY KEY,
game_genre VARCHAR(100),
primary_game VARCHAR(255)
)ENGINE=InnoDB;

-- Dimension: player demographics — one row per player (record_id)
CREATE TABLE IF NOT EXISTS Dim_Player (
    record_id varchar(20) PRIMARY KEY, 
    age INT,
    Age_Group VARCHAR(20),
    gender VARCHAR(20),
    Educational_State VARCHAR(100)
)ENGINE=InnoDB;


-- Dimension: sleep quality, disruption frequency, and derived sleep state
CREATE TABLE IF NOT EXISTS Dim_Sleep (
    Sleep_Id INT AUTO_INCREMENT PRIMARY KEY, 
    sleep_quality VARCHAR(50),
    sleep_disruption_frequency VARCHAR(50),
    Sleep_State VARCHAR(50)
)ENGINE=InnoDB;

-- Dimension: addiction symptoms + the overall addiction risk level
CREATE TABLE IF NOT EXISTS Dim_Addiction (
    Addiction_Id INT AUTO_INCREMENT PRIMARY KEY, 
    withdrawal_symptoms VARCHAR(50),
    loss_of_other_interests VARCHAR(50),
    continued_despite_problems VARCHAR(50),
    gaming_addiction_risk_level VARCHAR(50)
)ENGINE=InnoDB;

-- Dimension: physical symptoms (eye strain, back/neck pain) + risk label
CREATE TABLE IF NOT EXISTS Dim_PhysicalStatus (
    Physical_Id INT AUTO_INCREMENT PRIMARY KEY, 
    eye_strain VARCHAR(50),
    back_neck_pain VARCHAR(50),
    Physical_Pain VARCHAR(50)
)ENGINE=InnoDB;



-- Fact table: one row per player, holding every measure plus a foreign
-- key into each dimension above. record_id is both the primary key here
-- and the key Dim_Player is joined on.
-- ON DELETE SET NULL / ON UPDATE CASCADE on the platform FK means: if a
-- platform row is deleted the fact rows keep their data but lose that
-- link; if a platform's id changes, fact rows follow automatically.
CREATE TABLE IF NOT EXISTS Fact_Gaming_Mental_Health (
    record_id varchar(20) PRIMARY KEY, 
    Addiction_Id INT,
    Physical_Id INT,
    Sleep_Id INT,
    Game_Id INT,
    Platform_Id INT,

    daily_gaming_hours DECIMAL(4,2),
    Gaming_Hours_Category VARCHAR(50),
    sleep_hours DECIMAL(4,2),
    academic_work_performance VARCHAR(50),
    grades_gpa DECIMAL(3,2),
    work_productivity_score INT,
    mood_state VARCHAR(50),
    mood_swing_frequency VARCHAR(50),
    weight_change_kg DECIMAL(5,2),
    exercise_hours_weekly DECIMAL(4,2),
    social_isolation_score INT,
    face_to_face_social_hours_weekly DECIMAL(4,2),
    monthly_game_spending_usd DECIMAL(10,2),
    years_gaming INT,
    Total_spent INT,
    Spend_Category VARCHAR(50),
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_addiction FOREIGN KEY (Addiction_Id) REFERENCES Dim_Addiction(Addiction_Id),
    CONSTRAINT fk_physical FOREIGN KEY (Physical_Id) REFERENCES Dim_PhysicalStatus(Physical_Id),
    CONSTRAINT fk_sleep FOREIGN KEY (Sleep_Id) REFERENCES Dim_Sleep(Sleep_Id),
    CONSTRAINT fk_game FOREIGN KEY (Game_Id) REFERENCES Dim_Game(Game_Id),
    CONSTRAINT fk_player FOREIGN KEY (record_id) REFERENCES dim_player(record_id),
    CONSTRAINT fk_platform FOREIGN KEY (Platform_Id) REFERENCES Dim_Platform(Platform_Id)
	ON DELETE SET NULL
    ON UPDATE CASCADE
)ENGINE=InnoDB;
		



-- Populate Dim_Platform with each distinct platform value
INSERT INTO Dim_Platform (gaming_platform)
SELECT DISTINCT gaming_platform
FROM gaming_mental_health;

-- Output: 4 rows -> Console, Mobile, Multi-platform, PC
select* from Dim_Platform;

-- Populate Dim_Game with each distinct (genre, game) pair
INSERT INTO Dim_Game(game_genre,primary_game)
SELECT DISTINCT game_genre , primary_game
FROM gaming_mental_health;

-- Output: 24 distinct genre/game combinations
select* from Dim_Game;

-- Populate Dim_Player, one row per player
INSERT INTO Dim_Player ( 
	record_id,
    age,
    Age_Group,
    gender,
    Educational_State)
SELECT DISTINCT  record_id, age , age_group , gender , Educational_State
FROM gaming_mental_health;

-- Output: 1000 rows (one per player — record_id is unique)
select* from Dim_Player;

-- Populate Dim_Sleep with each distinct sleep-profile combination
INSERT INTO Dim_Sleep (
    sleep_quality ,
    sleep_disruption_frequency ,
    Sleep_State) 
SELECT DISTINCT
    sleep_quality ,
    sleep_disruption_frequency ,
    sleep_states
    FROM gaming_mental_health;

-- Output: 64 distinct combinations
select* from Dim_Sleep;

-- Populate Dim_Addiction with each distinct addiction-symptom combination
INSERT INTO Dim_Addiction (
    withdrawal_symptoms ,
    loss_of_other_interests ,
    continued_despite_problems ,
    gaming_addiction_risk_level)
SELECT DISTINCT
    withdrawal_symptoms ,
    loss_of_other_interests ,
    continued_despite_problems ,
    gaming_addiction_risk_level  
FROM gaming_mental_health;

-- Output: 15 distinct combinations
select* from Dim_Addiction;

-- Populate Dim_PhysicalStatus with each distinct symptom combination
INSERT INTO Dim_PhysicalStatus (
    eye_strain ,
    back_neck_pain,
    Physical_Pain) 
SELECT DISTINCT
    eye_strain ,
    back_neck_pain,
    Physical_Pain
    FROM gaming_mental_health;

-- Output: 4 distinct combinations (eye_strain x back_neck_pain, all 4 combos occur)
select* from Dim_PhysicalStatus;
   
-- Populate the fact table by joining the flat table back to every
-- dimension on its natural key, picking up each dimension's surrogate ID
   INSERT INTO Fact_Gaming_Mental_Health (
    record_id, Addiction_Id, Physical_Id, Sleep_Id, Game_Id, Platform_Id, daily_gaming_hours, 
    Gaming_Hours_Category, sleep_hours, academic_work_performance, grades_gpa, work_productivity_score, 
    mood_state,  mood_swing_frequency, weight_change_kg, exercise_hours_weekly, social_isolation_score, face_to_face_social_hours_weekly,
    monthly_game_spending_usd, years_gaming, Total_spent, Spend_Category
)
SELECT
    f.record_id,  a.Addiction_Id, ph.Physical_Id, s.Sleep_Id, g.Game_Id, p.Platform_Id, f.daily_gaming_hours, 
    f.Gaming_Hours_Category, f.sleep_hours, f.academic_work_performance, f.grades_gpa, f.work_productivity_score, f.mood_state, 
    f.mood_swing_frequency, f.weight_change_kg, f.exercise_hours_weekly, f.social_isolation_score, f.face_to_face_social_hours_weekly, 
    f.monthly_game_spending_usd, f.years_gaming, f.Total_spent, f.Spend_Category 
    
FROM gaming_mental_health as f
left join dim_addiction as a
	ON f.withdrawal_symptoms = a.withdrawal_symptoms 
    AND f.loss_of_other_interests = a.loss_of_other_interests 
    AND f.continued_despite_problems = a.continued_despite_problems 
    AND f.gaming_addiction_risk_level = a.gaming_addiction_risk_level
LEFT JOIN Dim_PhysicalStatus as ph 
    ON f.eye_strain = ph.eye_strain 
    AND f.back_neck_pain = ph.back_neck_pain 
    AND f.Physical_Pain = ph.Physical_Pain
LEFT JOIN Dim_Sleep as s 
    ON f.sleep_quality = s.sleep_quality 
    AND f.sleep_disruption_frequency = s.sleep_disruption_frequency 
    AND f.sleep_states = s.Sleep_State
LEFT JOIN Dim_Game as g 
    ON f.game_genre = g.game_genre 
    AND f.primary_game = g.primary_game
LEFT JOIN Dim_Platform as p 
    ON f.gaming_platform = p.gaming_platform;
    
   
-- Output: 1000 rows (full fact table, one row per player, all FKs resolved)
   select* from Fact_Gaming_Mental_Health;
   
-- ============================================================
-- ANALYSIS
-- ============================================================

-- Which specific games rack up the most total hours played?
-- Output (top 10): Elden Ring 368.7 | StarCraft II 355.1 | Dota 2 352.4 |
-- Civilization VI 346.2 | Final Fantasy XIV 314.2 | World of Warcraft 314.0 |
-- League of Legends 309.7 | Cyberpunk 2077 289.7 | Fortnite 282.7 |
-- Mobile Legends 268.0
SELECT g.primary_game,SUM(daily_gaming_hours) as Sum_hours
FROM fact_gaming_mental_health as f
left join dim_game as g
on g.Game_Id = f.Game_Id
group by g.primary_game
order by Sum_hours desc
limit 10;

-- Within each genre, which single game has the highest average daily hours?
with cte3 as(
SELECT
    g.game_genre,
    g.primary_game,
    round(AVG(f.daily_gaming_hours),2) AS Avg_Hours,
    RANK() OVER(
        PARTITION BY g.game_genre
        ORDER BY AVG(f.daily_gaming_hours) DESC
    ) AS Game_Rank
FROM Fact_Gaming_Mental_Health f
JOIN Dim_Game g
ON f.Game_Id = g.Game_Id
GROUP BY g.game_genre, g.primary_game
)

-- Output: Apex Legends (Battle Royale) 7.21 | Call of Duty (FPS) 6.53 |
-- Final Fantasy XIV (MMO) 6.69 | League of Legends (MOBA) 6.32 | 
-- Clash of Clans (Mobile Games) 6.67 | Elden Ring (RPG) 6.58  | Civilization VI (Strategy) 6.79 
select * from cte3 where Game_Rank =1;

-- Which genres generate the most total lifetime spend?
-- Output: MMO 1,146,881 | Strategy 1,115,695 | MOBA 1,109,873 | FPS 1,012,512 |
-- RPG 999,381 | Battle Royale 968,297 | Mobile Games 851,965
-- (only 7 genres exist in the data, so "limit 10" simply returns all of them)
SELECT g.game_genre,SUM(Total_spent) as Sum_Spent
FROM fact_gaming_mental_health as f
left join dim_game as g
on g.Game_Id = f.Game_Id
group by g.game_genre
order by Sum_Spent desc
limit 10;

-- Within each Spend_Category tier, which genre contributes the most spend?
with cte4 as(
select g.game_genre,
	sum(total_spent) as sum_spent,
	Spend_Category,
    dense_rank() over(partition by Spend_Category order by sum(total_spent) desc) as game_genre_rank
from fact_gaming_mental_health f
join dim_game as g
on g.Game_Id = f.Game_Id
group by Spend_Category,game_genre)

-- Output: High -> MMO 223,746 | Low -> MOBA 304,264 
--  Mid -> RPG 367,302 | Very High -> Strategy 405,154 
select * from cte4 where game_genre_rank =1;

-- Average gaming hours by gender, and each gender's share of the combined average
-- Output: Other avg=6.63 (35.22%) | Male avg=6.23 (33.08%) | Female avg=5.97 (31.70%)
SELECT gender,
	round(avg(daily_gaming_hours) ,2) as Avg_hours,
    concat(round(100 * avg(daily_gaming_hours) /sum(avg(daily_gaming_hours)) over() ,2)," %" ) as pct_total_hours
FROM fact_gaming_mental_health as f
left join dim_player as p
on p.record_id = f.record_id
group by gender
order by Avg_hours desc;

-- Total gaming hours by age group, and each group's share of all hours played
-- Output: Young Adult 3879.1 (63.06%) | Teenager 1994.4 (32.42%) | Adult 277.9 (4.52%)
SELECT age_group ,
	SUM(daily_gaming_hours) as Sum_hours,
    concat(round(100* sum(daily_gaming_hours)/sum(sum(daily_gaming_hours)) over(),2)," %") as pct_hours
FROM fact_gaming_mental_health as f
left join dim_player as p
on p.record_id = f.record_id
group by age_group
order by Sum_hours desc;

-- Breakdown of addiction risk level counts within each age group
-- Output:
-- Teenager:    High 47  | Low 172 | Moderate 64  | Severe 43
-- Young Adult: High 102 | Low 312 | Moderate 118 | Severe 92
-- Adult:       High 5   | Low 30  | Moderate 8   | Severe 7
SELECT p.age_group, 
	count( case when gaming_addiction_risk_level = "High" then 1 end) as High,
	count( case when gaming_addiction_risk_level = "low" then 1 end) as low,
	count( case when gaming_addiction_risk_level = "Moderate" then 1 end) as Moderate,
	count( case when gaming_addiction_risk_level = "Severe" then 1 end) as Severe
FROM fact_gaming_mental_health as f
left join dim_player as p
	on p.record_id = f.record_id
left join dim_addiction as a
	on a.Addiction_Id = f.Addiction_Id
group by p.age_group;


-- Does higher addiction risk correlate with more isolation and less
-- face-to-face social time? Output shows yes — isolation rises and
-- face-to-face hours fall monotonically as risk increases.
-- Output: Severe 6.5 / 3.2 | Low 2.5 iso / 10.2 hrs | High 5.5 / 4.6 | Moderate 4.3 / 6.7 
SELECT a.gaming_addiction_risk_level ,
round(AVG(f.social_isolation_score),1 )as Avg_ISO_Score ,
round(AVG(f.face_to_face_social_hours_weekly),1 ) as Avg_Face_To_Face
FROM fact_gaming_mental_health as f
left join dim_addiction as a
on a.Addiction_Id = f.Addiction_Id
group by gaming_addiction_risk_level;

-- Average lifetime spend by mood state
-- Output (desc): Anxious 10225.7 | Irritable 9766.9 | Depressed 7321.1 |
-- Restless 6948.9 | Withdrawn 6568.8 | Angry 6448.0 | Euphoric 5929.0 |
-- Normal 4529.9 | Excited 3109.1
SELECT mood_state , round(AVG(total_spent),1 )as Avg_Spent
FROM fact_gaming_mental_health
group by mood_state
order by Avg_Spent desc;

-- Average daily gaming hours by mood state
-- Output (desc): Anxious 7.3 | Irritable 7.0 | Restless 6.8 | Depressed 6.7 |
-- Withdrawn 6.7 | Angry 6.5 | Euphoric 5.7 | Normal 4.1 | Excited 3.5
SELECT mood_state , round(AVG(daily_gaming_hours),1 )as Avg_Hours
FROM fact_gaming_mental_health
group by mood_state
order by Avg_Hours desc;

-- For each platform, how many players report back/neck pain vs not?
-- Output: Console 88 true / 149 false | Mobile 94 / 168 |
-- Multi-platform 89 / 171 | PC 77 / 164
SELECT p.gaming_platform,
        count(case when back_neck_pain = "true" then 1 end) as count_true_back_neck_pain,
        count(case when back_neck_pain = "false" then 1 end) as count_false_back_neck_pain
FROM fact_gaming_mental_health f
join dim_platform p
	on p.Platform_Id = f.Platform_Id
join dim_physicalstatus py
	on py.Physical_Id = f.Physical_Id
group by gaming_platform;


-- Average daily gaming hours by physical-pain risk level
-- Output: High_Risk 8.3 | Moderate 7.1 | NO_Risk 3.9
SELECT physical_pain , round(AVG(daily_gaming_hours),1 ) as Avg_Hours
FROM fact_gaming_mental_health as f
left join dim_physicalstatus as ph
on ph.Physical_Id = f.Physical_Id
group by physical_pain
order by Avg_Hours;

-- Average daily gaming hours by self-reported academic/work performance
-- Output (desc): Failing 8.52 | Poor 8.08 | Below Average 6.90 |
-- Average 5.67 | Good 4.27 | Excellent 3.94
-- -> a clear inverse relationship between gaming hours and performance
SELECT academic_work_performance , round(avg(daily_gaming_hours) ,2)as avg_hours
FROM fact_gaming_mental_health
group by academic_work_performance
order by avg_hours desc;


-- Average sleep hours by self-reported sleep quality
-- Output (desc): Good 6.85 | Fair 6.04 | Poor 5.25 | Very Poor 4.88 | Insomnia 4.75
SELECT sleep_quality , round(AVG(sleep_hours) ,2) as avg_sleep
FROM fact_gaming_mental_health f
join dim_sleep s
	on s.Sleep_Id = f.Sleep_Id
group by sleep_quality
order by avg_sleep desc;

-- ----------- KPIs -----------
-- Single headline numbers, typically wired into BI tool KPI cards.
-- All combined into one query instead of ten separate ones, since they
-- all aggregate over the same table with no grouping or joins needed.
-- Output:
-- Player_count=1000 | sum_gaming_hours=6151.4 | avg_gaming_hours=6.15 |
-- Total_Spent=7,204,604 | avg_work_productivity_score=5.39 | avg_gpa=2.52 |
-- avg_exercise_hours_weekly=6.95 | avg_sleep_hours=5.74 |
-- avg_face_to_face_social_hours_weekly=7.65 | avg_social_isolation_score=3.87
SELECT
    COUNT(record_id) AS Player_count,
    SUM(daily_gaming_hours) AS sum_gaming_hours,
    round(AVG(daily_gaming_hours), 2) AS avg_gaming_hours,
    SUM(Total_spent) AS Total_Spent,
    round(AVG(work_productivity_score), 2) AS avg_work_productivity_score,
    round(AVG(grades_gpa), 2) AS avg_gpa,
    round(AVG(exercise_hours_weekly), 2) AS avg_exercise_hours_weekly,
    round(AVG(sleep_hours), 2) AS avg_sleep_hours,
    round(AVG(face_to_face_social_hours_weekly), 2) AS avg_face_to_face_social_hours_weekly,
    round(AVG(social_isolation_score), 2) AS avg_social_isolation_score
FROM Gaming_Mental_Health;

-- ---------------------------------------------------------------------

-- ----------- GENERAL KPIs -----------
-- Output: Player_count=1000 | male_pct=64.7% | female_pct=33.1% | avg_gaming_hours=6.15 
SELECT
    COUNT(p.record_id) AS Player_count,
    CONCAT(ROUND(100 * SUM(CASE WHEN p.gender = "male" THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS Male_pct,
    CONCAT(ROUND(100 * SUM(CASE WHEN p.gender = "female" THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS Female_pct,
    round(AVG(f.daily_gaming_hours), 2) AS avg_gaming_hours
FROM Fact_Gaming_Mental_Health f
JOIN dim_player p
	on f.record_id = p.record_id;
 
-- ----------- SLEEP & WELLBEING KPIs -----------
-- Output: avg_sleep_hours=5.74 | avg_exercise_hours_weekly=6.95 | avg_weight_change_kg=1.51
SELECT
    round(AVG(sleep_hours), 2) AS avg_sleep_hours,
    round(AVG(exercise_hours_weekly), 2) AS avg_exercise_hours_weekly,
    round(AVG(weight_change_kg), 2) AS avg_weight_change_kg
FROM Fact_Gaming_Mental_Health;
 
 
-- ----------- ADDICTION RISK KPIs -----------
-- Output: pct_low_risk=51.4% | pct_moderate_risk=19.0% | pct_high_risk=15.4% |
-- pct_severe_risk=14.2% | avg_social_isolation_score=3.87 | avg_face_to_face_hours_weekly=7.65
SELECT
    concat(round(100 * SUM(CASE WHEN a.gaming_addiction_risk_level = 'Low' THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS pct_low_risk,
    concat(round(100 * SUM(CASE WHEN a.gaming_addiction_risk_level = 'Moderate' THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS pct_moderate_risk,
    concat(round(100 * SUM(CASE WHEN a.gaming_addiction_risk_level = 'High' THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS pct_high_risk,
    concat(round(100 * SUM(CASE WHEN a.gaming_addiction_risk_level = 'Severe' THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS pct_severe_risk,
    round(AVG(f.social_isolation_score), 2) AS avg_social_isolation_score,
    round(AVG(f.face_to_face_social_hours_weekly), 2) AS avg_face_to_face_hours_weekly
FROM Fact_Gaming_Mental_Health f
LEFT JOIN Dim_Addiction a 
	ON a.Addiction_Id = f.Addiction_Id;
 
 
-- ----------- SPENDING KPIs -----------
-- Output: total_lifetime_spend=7,204,604 | avg_lifetime_spend=7204.60 | avg_monthly_spend=105.22 
SELECT
    SUM(Total_spent) AS total_lifetime_spend,
    round(AVG(Total_spent), 2) AS avg_lifetime_spend,
    round(AVG(monthly_game_spending_usd), 2) AS avg_monthly_spend
FROM Fact_Gaming_Mental_Health;
 
 
-- ----------- PHYSICAL HEALTH KPIs -----------
-- Output: pct_eye_strain=49.7% | pct_back_neck_pain=34.8% |
-- pct_high_risk_physical=23.6% | pct_moderate_risk_physical=37.3% |
-- pct_no_risk_physical=39.1%
SELECT
    concat(round(100 * SUM(CASE WHEN ph.eye_strain = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS pct_eye_strain,
    concat(round(100 * SUM(CASE WHEN ph.back_neck_pain = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 1), " %") AS pct_back_neck_pain,
    concat(round(100 * SUM(CASE WHEN ph.Physical_Pain = 'High_Risk' THEN 1 ELSE 0 END) / COUNT(*), 1), " %")  AS pct_high_risk_physical,
    concat(round(100 * SUM(CASE WHEN ph.Physical_Pain = 'Moderate' THEN 1 ELSE 0 END) / COUNT(*), 1), " %")  AS pct_moderate_risk_physical,
    concat(round(100 * SUM(CASE WHEN ph.Physical_Pain = 'NO_Risk' THEN 1 ELSE 0 END) / COUNT(*), 1), " %")  AS pct_no_risk_physical
FROM Fact_Gaming_Mental_Health f
LEFT JOIN Dim_PhysicalStatus ph ON ph.Physical_Id = f.Physical_Id;
 

-- ----------- ACADEMIC & PRODUCTIVITY KPIs -----------
-- Output: 
-- gender | male_avg_gpa | avg_work_productivity_score
-- Male	  |   2.50	     |        5.40
-- Female |	  2.57	     |        5.33
-- Other  |	  2.25	     |        6.13
 SELECT 
	gender,
    round(AVG(grades_gpa),2) AS male_avg_gpa,
	round(AVG(work_productivity_score),2) avg_work_productivity_score
FROM Fact_Gaming_Mental_Health f
JOIN Dim_Player p
	ON p.record_id = f.record_id
group by gender;