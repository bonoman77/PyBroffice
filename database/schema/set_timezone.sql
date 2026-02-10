-- MySQL 서버 타임존을 한국시간으로 설정
-- 이 스크립트는 관리자 권한으로 실행해야 합니다

-- 전역 타임존 설정 (관리자 권한 필요)
SET GLOBAL time_zone = '+09:00';

-- 현재 세션 타임존 설정
SET time_zone = '+09:00';
SET SESSION time_zone = '+09:00';

-- 확인
SELECT @@global.time_zone;
SELECT @@session.time_zone;
SELECT NOW();
