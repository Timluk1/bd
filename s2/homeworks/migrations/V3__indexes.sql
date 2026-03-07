-- V3__indexes.sql: индексы для полнотекстового поиска, JSONB, массивов, геометрии и range

-- Полнотекстовый поиск (GIN)
CREATE INDEX idx_track_search ON track USING GIN (search_vector);
CREATE INDEX idx_comment_search ON comment USING GIN (search_vector);

-- JSONB (GIN)
CREATE INDEX idx_track_metadata ON track USING GIN (metadata);
CREATE INDEX idx_user_preferences ON "user" USING GIN (preferences);
CREATE INDEX idx_comment_reactions ON comment USING GIN (reactions);
CREATE INDEX idx_listening_context ON listening_history USING GIN (context);

-- Массивы (GIN)
CREATE INDEX idx_track_tags ON track USING GIN (tags);
CREATE INDEX idx_user_genres ON "user" USING GIN (favorite_genres);

-- Геометрический тип (GiST)
CREATE INDEX idx_listening_location ON listening_history USING GIST (location);

-- Range-типы (GiST)
CREATE INDEX idx_user_sub_period ON "user" USING GIST (subscription_period);
CREATE INDEX idx_listening_duration ON listening_history USING GIST (listen_duration);
