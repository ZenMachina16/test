import React from 'react';
import SearchIcon from '@/assets/test_Search.svg';
import FilterIcon from '@/assets/test_Filter.svg';
import './SearchFilterBar.css';

const SearchFilterBar = ({ onSearchChange, value }) => {
  return (
    <div className="search-filter-bar">
      <div className="search-box">
        <img src={SearchIcon} alt="Search Icon" className="icon" />
        <input
          type="text"
          placeholder="Search Customers"
          value={value}
          onChange={(e) => onSearchChange?.(e.target.value)}
        />
      </div>
      <div className="filter-box">
        <img src={FilterIcon} alt="Filter Icon" className="icon" />
        <span>Add Filters</span>
        <div className="dropdown">
          <div className="dropdown-item">Filter 1</div>
          <div className="dropdown-item">Filter 2</div>
          <div className="dropdown-item">Filter 3</div>
          <div className="dropdown-item">Filter 4</div>
        </div>
      </div>
    </div>
  );
};

export default SearchFilterBar;
