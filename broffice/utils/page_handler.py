
from typing import Dict, Union


def paged_list(
    total: int,
    page: Union[int, str] = 1,
    page_group_size: int = 5,
    row_size: int = 10
) -> Dict[str, Union[int, bool]]:
    """
    페이지네이션 정보 생성
    
    Args:
        total: 전체 항목 수
        page: 현재 페이지 번호 (1부터 시작)
        page_group_size: 페이지 그룹 크기 (한 번에 표시할 페이지 번호 개수)
        row_size: 페이지당 항목 수
    
    Returns:
        dict: 페이지네이션 정보
            - page: 현재 페이지
            - offset: DB 쿼리용 오프셋
            - row_size: 페이지당 항목 수
            - total_pages: 전체 페이지 수
            - start_page: 현재 그룹의 시작 페이지
            - end_page: 현재 그룹의 끝 페이지
            - has_prev: 이전 그룹 존재 여부
            - prev_page: 이전 그룹의 마지막 페이지
            - has_next: 다음 그룹 존재 여부
            - next_page: 다음 그룹의 첫 페이지
    
    Example:
        >>> paged_list(total=100, page=1, page_group_size=5, row_size=10)
        {
            'page': 1,
            'offset': 0,
            'row_size': 10,
            'total_pages': 10,
            'start_page': 1,
            'end_page': 5,
            'has_prev': False,
            'prev_page': 1,
            'has_next': True,
            'next_page': 6
        }
    """
    # 입력 검증 및 변환
    try:
        page = int(page) if page else 1
        total = int(total) if total else 0
        page_group_size = int(page_group_size) if page_group_size else 5
        row_size = int(row_size) if row_size else 10
    except (ValueError, TypeError):
        # 변환 실패 시 기본값 사용
        page = 1
        total = 0
        page_group_size = 5
        row_size = 10
    
    # 유효성 검증
    page = max(1, page)  # 최소 1
    total = max(0, total)  # 최소 0
    page_group_size = max(1, page_group_size)  # 최소 1
    row_size = max(1, row_size)  # 최소 1
    
    # 전체 페이지 수 계산
    total_pages = (total + row_size - 1) // row_size if total > 0 else 1
    
    # 현재 페이지가 전체 페이지를 초과하면 마지막 페이지로 조정
    page = min(page, total_pages)
    
    # DB 쿼리용 오프셋 계산
    offset = (page - 1) * row_size
    
    # 현재 페이지 그룹의 시작/끝 페이지 계산
    start_page = ((page - 1) // page_group_size) * page_group_size + 1
    end_page = min(start_page + page_group_size - 1, total_pages)
    
    # 이전/다음 그룹 존재 여부
    has_prev = start_page > 1
    has_next = end_page < total_pages
    
    # 이전/다음 그룹의 페이지 번호
    prev_page = max(1, start_page - 1)
    next_page = min(end_page + 1, total_pages)
    
    return {
        'page': page,
        'offset': offset,
        'row_size': row_size,
        'total_pages': total_pages,
        'start_page': start_page,
        'end_page': end_page,
        'has_prev': has_prev,
        'prev_page': prev_page,
        'has_next': has_next,
        'next_page': next_page,
    }

