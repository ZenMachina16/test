import React, { useEffect, useMemo, useRef, useState } from 'react';
import './CustomerList.css';
import UserIcon from '@/assets/test_user.svg';

// Utility to generate 1 million customer records
const generateCustomers = () => {
  const customers = [];
  for (let i = 0; i < 1000000; i++) {
    customers.push({
      id: i + 1,
      name: `Customer Name`,
      phone: `+917600600001`,
      email: `doe.john@gmail.com`,
      score: 23,
      lastMessageAt: 'July 22 2024, 12:45 PM',
      addedBy: 'Kartikey Mishra',
      avatar: 'https://via.placeholder.com/40'
    });
  }
  return customers;
};

const CustomerList = ({ searchQuery = '' }) => {
  const [customers, setCustomers] = useState([]);
  const [selectedCustomers, setSelectedCustomers] = useState([]);
  const [sortConfig, setSortConfig] = useState({ key: 'id', direction: 'asc' });
  const [visibleCount, setVisibleCount] = useState(30);
  const sentinelRef = useRef(null);

  useEffect(() => {
    setCustomers(generateCustomers());
  }, []);

  // Function to handle sorting
  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  // Function to handle select all
  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelectedCustomers(customers.map(customer => customer.id));
    } else {
      setSelectedCustomers([]);
    }
  };

  // Function to handle individual selection
  const handleSelect = (id) => {
    setSelectedCustomers(prevSelected =>
      prevSelected.includes(id)
        ? prevSelected.filter(customerId => customerId !== id)
        : [...prevSelected, id]
    );
  };

  const filteredCustomers = useMemo(() => {
    if (!searchQuery) return customers;
    const q = searchQuery.toLowerCase();
    return customers.filter((c) =>
      c.name.toLowerCase().includes(q) ||
      c.email.toLowerCase().includes(q) ||
      c.phone.toLowerCase().includes(q)
    );
  }, [customers, searchQuery]);

  const sortedCustomers = useMemo(() => {
    const arr = [...filteredCustomers];
    arr.sort((a, b) => {
      const aVal = a[sortConfig.key];
      const bVal = b[sortConfig.key];
      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
    return arr;
  }, [filteredCustomers, sortConfig]);

  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;
    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        setVisibleCount((prev) => Math.min(prev + 30, sortedCustomers.length));
      }
    });
    observer.observe(el);
    return () => observer.disconnect();
  }, [sortedCustomers.length]);

  useEffect(() => {
    // reset visible rows when search or sort changes
    setVisibleCount(30);
  }, [searchQuery, sortConfig.key, sortConfig.direction]);

  return (
    <div className="customer-list">
      <table>
        <thead>
          <tr>
            <th>
              <input
                type="checkbox"
                onChange={handleSelectAll}
                checked={selectedCustomers.length === customers.length}
              />
            </th>
            <th onClick={() => handleSort('name')}>Customer</th>
            <th onClick={() => handleSort('score')}>Score</th>
            <th onClick={() => handleSort('email')}>Email</th>
            <th style={{ width: '30%' }}></th> {/* Increased gap in the middle */}
            <th onClick={() => handleSort('lastMessageAt')}>Last message seen at</th>
            <th onClick={() => handleSort('addedBy')}>Added By</th>
          </tr>
        </thead>
        <tbody>
          {sortedCustomers.slice(0, visibleCount).map(customer => (
            <tr key={customer.id}>
              <td>
                <input
                  type="checkbox"
                  checked={selectedCustomers.includes(customer.id)}
                  onChange={() => handleSelect(customer.id)}
                />
              </td>
              <td>
                <div>
                  {customer.name}
                  <br />
                  {customer.phone}
                </div>
              </td>
              <td>{customer.score}</td>
              <td>{customer.email}</td>
              <td style={{ width: '20%' }}></td> {/* Space in the middle */}
              <td>{customer.lastMessageAt}</td>
              <td>
                {customer.addedBy === 'Kartikey Mishra' && (
                  <img src={UserIcon} alt="User Icon" style={{ marginRight: '5px', verticalAlign: 'middle' }} />
                )}
                {customer.addedBy}
              </td>
            </tr>
          ))}
          <tr>
            <td colSpan={7}>
              <div ref={sentinelRef} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

export default CustomerList;
