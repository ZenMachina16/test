import React from 'react';
import DoubletickLogo from '@/assets/DoubletickLogo.png';
import './Header.css';

const Header = () => {
  return (
    <>
      <div className="header">
        <img src={DoubletickLogo} alt="Doubletick Logo" className="logo" />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', padding: '10px 0' }}>
        <span style={{ fontSize: '1.2rem', fontWeight: 'bold', color: 'black' }}>All freaking Customers</span>
        <span style={{ color: 'green', marginLeft: '10px', fontSize: '1.5rem', fontWeight: 'bold' }}>1230</span>
      </div>
    </>
  );
};

export default Header;
