-- ==========================================
-- slAI - Initial Database Schema
-- Migration: V1
-- Database: PostgreSQL
-- ==========================================

-- 1. USERS
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'USER',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_users_role
        CHECK (role IN ('USER', 'ADMIN')),

    -- Usernames are shown to people, so two users cannot share one.
    CONSTRAINT uq_users_username
        UNIQUE (username)
);

-- Emails should be unique regardless of letter casing.
CREATE UNIQUE INDEX uq_users_email_lower
    ON users (LOWER(email));


-- 2. AESTHETICS
CREATE TABLE aesthetics (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- 3. CLOTHING ITEMS
CREATE TABLE clothing_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    category VARCHAR(50),
    colour VARCHAR(50),
    secondary_colours JSONB NOT NULL DEFAULT '[]'::JSONB,
    pattern VARCHAR(50),
    style_tags JSONB NOT NULL DEFAULT '[]'::JSONB,
    image_key VARCHAR(500) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    ai_raw_response JSONB,
    user_corrected BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_clothing_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT chk_clothing_status
        CHECK (status IN ('PENDING', 'PROCESSING', 'READY', 'FAILED')),

    -- A READY item is offered to the outfit generator, so it must have a category.
    CONSTRAINT chk_clothing_category_ready
        CHECK (status <> 'READY' OR category IS NOT NULL),

    -- Required for the composite ownership constraint below.
    CONSTRAINT uq_clothing_id_user
        UNIQUE (id, user_id)
);


-- 4. USER AESTHETIC PREFERENCES
CREATE TABLE user_aesthetics (
    user_id BIGINT NOT NULL,
    aesthetic_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, aesthetic_id),

    CONSTRAINT fk_user_aesthetics_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_user_aesthetics_aesthetic
        FOREIGN KEY (aesthetic_id) REFERENCES aesthetics(id)
        ON DELETE CASCADE
);


-- 5. OUTFITS
CREATE TABLE outfits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    aesthetic_id BIGINT NOT NULL,
    name VARCHAR(150),
    occasion VARCHAR(100),
    explanation TEXT,
    is_favourite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_outfits_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_outfits_aesthetic
        FOREIGN KEY (aesthetic_id) REFERENCES aesthetics(id),

    -- Required for the composite ownership constraint below.
    CONSTRAINT uq_outfits_id_user
        UNIQUE (id, user_id)
);


-- 6. OUTFIT ITEMS
CREATE TABLE outfit_items (
    outfit_id BIGINT NOT NULL,
    clothing_item_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    -- The outfit validator needs to know which slot (top, shoes...) each item fills.
    slot VARCHAR(50) NOT NULL,

    PRIMARY KEY (outfit_id, clothing_item_id),

    -- An outfit must belong to the specified user.
    CONSTRAINT fk_outfit_items_outfit_owner
        FOREIGN KEY (outfit_id, user_id)
        REFERENCES outfits(id, user_id)
        ON DELETE CASCADE,

    -- The clothing item must belong to that same user.
    CONSTRAINT fk_outfit_items_clothing_owner
        FOREIGN KEY (clothing_item_id, user_id)
        REFERENCES clothing_items(id, user_id)
        ON DELETE CASCADE
);


-- ==========================================
-- INDEXES
-- ==========================================

CREATE INDEX idx_clothing_items_user
    ON clothing_items(user_id);

CREATE INDEX idx_clothing_items_user_status
    ON clothing_items(user_id, status);

CREATE INDEX idx_user_aesthetics_aesthetic
    ON user_aesthetics(aesthetic_id);

CREATE INDEX idx_outfits_user
    ON outfits(user_id);

CREATE INDEX idx_outfits_aesthetic
    ON outfits(aesthetic_id);

CREATE INDEX idx_outfits_user_created
    ON outfits(user_id, created_at DESC);

CREATE INDEX idx_outfit_items_clothing
    ON outfit_items(clothing_item_id);


-- ==========================================
-- INITIAL AESTHETIC DATA
-- ==========================================

INSERT INTO aesthetics (name, slug, description) VALUES
('Coquette', 'coquette', 'Romantic, feminine and delicate styling.'),
('Clean Girl', 'clean-girl', 'Minimal, polished and effortless styling.'),
('Dark Academia', 'dark-academia', 'Classic, scholarly and vintage-inspired styling.'),
('Streetwear', 'streetwear', 'Casual, urban and contemporary styling.'),
('Old Money', 'old-money', 'Timeless, understated and elegant styling.'),
('Y2K', 'y2k', 'Fashion inspired by the late 1990s and early 2000s.'),
('Cottagecore', 'cottagecore', 'Nature-inspired, vintage and romantic styling.'),
('Grunge', 'grunge', 'Alternative, relaxed and edgy styling.');
