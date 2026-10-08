# Part 1: Types and logical comparisons ----

## Types -----
x <- 1
typeof(x)
class(x)
is.numeric(x)
is.character(x)
as.character(x)
x + 1

x <- "Hello"
typeof(x)
is.numeric(x)
is.character(x)
as.numeric(x)
try(x + ", World")
paste0(x, ", World")


## How do we use logical statements? ----
x <- c(0, 1, 2, 3, NA)
ifelse(NA %in% x, "x contains a missing value", "x does not contain a missing value")

x <- c(0, 1, 2, 3)
ifelse(NA %in% x, "x contains a missing value", "x does not contain a missing value")

# Part 2: dplyr -----

library(tidyverse) # loads dplyr
ds <- starwars # loads built-in star wars database

## glimpse ----
glimpse(ds)

## arrange ----
arrange(ds, name)
arrange(ds, desc(height), mass)
arrange(ds, eye_color, hair_color)

## filter ----
filter(ds, name == "Yoda")
filter(ds, is.na(hair_color))
filter(ds, height > 100, height < 150)
filter(ds, eye_color %in% c("blue", "brown"))
filter(ds, !(eye_color %in% c("blue", "brown")))
filter(ds, height < 100)
filter_out(ds, height >= 100)

## Soft-coded vs. hard-coded position subset
filter(starwars, name == "Darth Vader")
starwars[4, ]

## slice ----
slice(ds, 10:15)
slice_head(ds, n = 5)
slice_tail(ds, n = 5)
slice_sample(ds, n = 2)
slice_sample(ds, n = 2)
slice_min(ds, height, n = 3)

## select ----
select(ds, name, height, mass)
select(ds, c("name", "height", "mass"))
select(ds, name:eye_color)
select(ds, -(eye_color:starships))
select(ds, ends_with("color"))
select(ds, contains("_"))
select(ds, where(is.numeric))
select(ds, where(is.character))

## select with bad names
bad_names <- tibble(id = 1, depression_1 = 1:5, dep2 = 1:5, DEP3 = 1:5, depressed = T)
select(bad_names, starts_with("dep"))
select(bad_names, starts_with("dep") & !matches("depressed"))

## select with good names
good_names <- tibble(id = 1, dep_1 = 1:5, dep_2 = 1:5, dep_3 = 1:5, is_depressed = T)
select(good_names, starts_with("dep"))
select(good_names, matches("_[0-9]"))
select(good_names, num_range(prefix = "dep_", range = 1:3))

## assignment ----
ds <- select(ds, name, height, eye_color)
ds <- arrange(ds, height, eye_color)
ds <- filter(ds, height < 70)

# Using intermediate assignments
ds <- starwars
ds_name_height_eye_color <- select(ds, name, height, eye_color)
ds_sorted <- arrange(ds_name_height_eye_color, height, eye_color)
ds_sorted_filtered <- filter(ds_sorted, height < 70)
ds_sorted_filtered

## pipe ----
ds <- starwars
ds <- ds %>% select(name, height, eye_color)

ds <- ds %>%
  select(name, eye_color) %>%
  arrange(eye_color) %>%
  filter(eye_color == "blue")

# Assigning the result of a piped expression

ds <- ds %>%
  select(height) %>%
  slice_tail(n = 5)
ds %>%
  select(height) %>%
  slice_tail(n = 5) -> ds
ds <- select(ds, height) %>% slice_tail(n = 5)
ds <- slice_tail(select(ds, height), n = 5)
ds <- starwars

## rename ----
iris
iris %>% rename(sepal_length = Sepal.Length)
iris %>% rename(sepal_length = Sepal.Length, sepal_width = Sepal.Width, petal_length = Petal.Length, petal_width = Petal.Width, species = Species)
iris %>% rename_with(toupper)
iris %>% rename_with(tolower, starts_with("Petal"))

lookup <- c(
  pet_length = "Petal.Length", pet_width = "Petal.Width",
  sep_length = "Sepal.Length", sep_width = "Sepal.Width"
)
iris %>% rename(all_of(lookup))

library(janitor)
iris %>% clean_names()
iris %>% clean_names("lower_camel")
iris %>% clean_names("title")

## mutate ----
ds <- starwars %>% select(name, mass, height, hair_color)
ds <- ds %>% mutate(in_movie = TRUE, .before = 1)
ds <- ds %>%
  mutate(
    height_m = height / 100,
    bmi = mass / (height_m^2),
    bmi = round(bmi), .after = "height"
  ) %>%
  arrange(desc(bmi))

ds <- ds %>%
  filter(hair_color %in% c("blond", NA)) %>%
  mutate(hair_color = ifelse(is.na(hair_color), "no hair", hair_color))

# Common task: Changing some but not all values within a column

ds <- starwars %>% select(name, height, hair_color)
ds <- ds %>% mutate(hair_color = replace_values(hair_color, NA ~ "no hair"))
ds <- ds %>% mutate(height = ifelse(height > 100, 100, height))
ds

## summarize ----
ds <- starwars %>% select(name, mass, height, species, sex)
ds %>% summarize(min_height = min(height))
ds %>% summarize(min_height = min(height, na.rm = T))

ds %>% summarize(
  min_height = min(height, na.rm = T),
  m_height = mean(height, na.rm = T),
  max_height = max(height, na.rm = T)
)

# summarize with group_by
ds %>%
  group_by(species, sex) %>%
  summarize(
    min_height = min(height, na.rm = T),
    m_height = mean(height, na.rm = T),
    max_height = max(height, na.rm = T),
    n = n()
  ) %>%
  filter(n > 1)

# Check the resulting tibble for grouping/retained variables
ds %>%
  group_by(species, sex) %>%
  summarize(max_height = max(height, na.rm = T))
ds %>%
  group_by(species, sex) %>%
  summarize(max_height = max(height, na.rm = T)) %>%
  ungroup()
ds %>%
  group_by(species, sex) %>%
  slice_max(height)

# Tedious summarizing
iris %>%
  clean_names() %>%
  group_by(species) %>%
  summarize(
    sepal_length_mean = mean(sepal_length),
    sepal_width_mean = mean(sepal_width),
    petal_length_mean = mean(petal_length),
    petal_width_mean = mean(petal_length)
  )

## across ----
iris %>%
  clean_names() %>%
  group_by(species) %>%
  summarize(across(everything(), mean, .names = "{.col}_mean"))

iris %>%
  clean_names() %>%
  group_by(species) %>%
  summarize(across(ends_with("length"), list(mean = mean, sd = sd)))

# Part 3: Code style ----

## Spaces ----
  
# Strive for
z <- (a + b)^2 / d

# Avoid
z<-( a + b ) ^ 2/d

# Strive for
mean(x, na.rm = TRUE)

# Avoid
mean (x ,na.rm=TRUE)

## Styling Pipes ----

# Strive for 
flights %>%   
  filter(!is.na(arr_delay), !is.na(tailnum)) %>%  
  count(dest)

# Avoid
flights%>%filter(!is.na(arr_delay), !is.na(tailnum))%>%count(dest)

# Strive for 
flights %>%   
  group_by(tailnum) %>% 
  summarize(
    delay = mean(arr_delay, na.rm = TRUE),
    n = n()
  )

# Avoid (lacks visual cue for what is part of summarize)
flights%>%
  group_by(tailnum) %>% 
  summarize(
    delay = mean(arr_delay, na.rm = TRUE), 
    n = n()
  )

# install.packages("styler") and use from 'Addins'
# All the code in Parts 1-2 was run through styler